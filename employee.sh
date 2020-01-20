#!/usr/bin/env bash

# shell variables

JSON='json'
JIRA_JSON='jira-json'
SEND='send'
KRED="\x1B[31m"
KNRM="\x1B[0m"
KGRN="\x1B[32m"
KYEL="\x1B[33m"
KGRY="\x1b[36m"
sendEmailFile='emailFile'
printFile=`mktemp`
tempomanager=''

trap "rm -f ${JIRA_JSON} ${JSON} ${sendEmailFile} ${printFile} ${SEND}"  SIGINT SIGKILL SIGQUIT SIGSEGV SIGPIPE SIGALRM SIGTERM EXIT

# utility function

function OK() {
    printf $KGRN"OK: "$KNRM
    printf "%s " "[ $@ ]"
    printf "\n"
}

function NOTICE() {
    printf $KGRY"NOTICE: "$KNRM
    printf "%s " "[ $@ ]"
    printf "\n"
}

function WARNING() {
    printf $KYEL"WARNING: "$KNRM
    printf "%s " "[ $@ ]"
    printf "\n"
}

function ERROR() {
    printf $KRED"ERROR: "$KNRM
    printf "%s " "$@"
    printf "\n"
    exit 1
}

function CHECK_FULLNAME_LENGTH() {
    if [[ $1 -gt 20 ]] ; then
        ERROR 'Lenght of name.surname is' ${COUNT}'. Please, shorten length of fullname and retry.' # AD cuts every symbol above 20.
    fi
}

function CHECK_FULLNAME_COUNT() {
    if [[ ${#eng[@]} -ne 2 ]] ; then
        ERROR 'Expected only name and surname separated with space (e.g Ivan Ivanov). Please, retry.'
    fi
}

function CHECK_DIGITS() {
    if [[ $1 =~ [0-9] ]]
    then
        ERROR 'Input contains digits.' # Fullname shouldn't containt digits
    fi
}

function textToHTML(){
    echo "<br>" >> ${SEND}
    echo "$@" >> ${SEND}
}

function prepare() {
    unset ALL_GROUPS
    NOTICE 'Input new employee name and surname (e.g Ivan Ivanov)'\n
    NOTICE 'Full name length should be less than 20 characters!'

    while read -r -a eng; do
        for word in "${eng[@]}"; do
            NAME=${eng[0]}
            SURNAME=${eng[1]}
            NAMEANDSURNAME="${eng[@]}"
        done
        break;
    done

    CHECK_DIGITS "$NAMEANDSURNAME"
    CHECK_FULLNAME_COUNT "$NAMEANDSURNAME"

    NAME_LOWER=$( echo $NAME | tr "[:upper:]" "[:lower:]")
    SURNAME_LOWER=$( echo $SURNAME | tr "[:upper:]" "[:lower:]")
    NAMEANDSURNAME_LOWER=$( echo $NAMEANDSURNAME | tr "[:upper:]" "[:lower:]")
    EMAIL="$NAME_LOWER.$SURNAME_LOWER@yourcompany.net"
    COUNT=$(echo $NAME_LOWER.$SURNAME_LOWER | wc -c)

    CHECK_FULLNAME_LENGTH "$COUNT"

    OK 'Full name is' ${NAME_LOWER}'.'${SURNAME_LOWER}
    OK 'Your email is' "$NAME_LOWER.$SURNAME_LOWER@yourcompany.net"

    NOTICE 'Please, select user department: php dotnet java javascript android ios qa design businessanalysts pm hr sales marketing'
    read userDepartment
    userDepartment=${userDepartment:?"User department is empty"}

    NOTICE 'Please, input employee position in format: Job Title'
    NOTICE 'ex.: Junior Python Developer or Project Manager or DevOps Engineer'
    read position
    position=${position:?"User position is empty"}

    NOTICE 'Please, select employee location: minsk kiev oslo helsinki london newyork paloalto'
    read location
    location=${location:?"User location is empty"}
    location_uppercase=$( echo ${location^})

    NOTICE 'Please, input employee phone number in format: country code + city\operator code + number'
    NOTICE 'ex.: 8 029 352-17-97 or +375 29 352-17-97 or +375293521797'
    read phone_number
    phone_number=${phone_number:?"User phone is empty"}

    NOTICE 'Generating password'
    PASSWD=`cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-zA-Z0-9!@^' | fold -w 14 | head -n 1`
    OK 'Password is' ${PASSWD}

    textToHTML 'Glad to see you in our friendly team! All your credentials are here: '
    textToHTML 'Email:' $EMAIL 'with password: ' $PASSWD
    textToHTML 'Password from your MacBook: ChangeMe'
    textToHTML 'Confluence:' $NAME_LOWER.$SURNAME_LOWER  'with password: ' $PASSWD
    textToHTML 'CI and old gitlab:' $NAME_LOWER.$SURNAME_LOWER 'with password: ' $PASSWD
    textToHTML 'Now you can login in Jira, Gmail, Gitlab with Google icon (login with Google).'
    textToHTML '<hr>'
    textToHTML 'URLS: '
    textToHTML 'Jira: https://yourjiraportal.atlassian.net'
    textToHTML 'Confluence: https://doc.yourdomain.info'
    textToHTML 'Gitlab: https://gitlab.yourdomain.info'
    textToHTML 'CI (Jenkins): https://jenkins.yourdomain.info'
    textToHTML '<hr>'
    textToHTML 'Get acquainted with Employee Book and other important info'
    textToHTML 'https://doc.yourdomain.info/display/GEN/Company+Structure'
    textToHTML 'https://doc.yourdomain.info/display/GEN/Contacts'
    textToHTML 'If you need any assistance please send your request to our ServiceDesk: https://yourjiraportal.atlassian.net/servicedesk/customer/portals'
}

function createGoogleUser(){
    userName="$NAME_LOWER.$SURNAME_LOWER"
    createUser=`/root/bin/gam/gam create user ${userName} firstname ${NAME} lastname ${SURNAME} password ${PASSWD} organization name "yourcompany Group" type unknown title "${position}" department "${location_uppercase} office" location ${location_uppercase} primary phone type mobile value "${phone_number}" primary 2>&1`
    checkGoogleVariables ${createUser}
    NOTICE 'Creating user in Google Apps'
    selectGoogleGroups
    updateGoogleGroups
    NOTICE 'Print user info'
    userInfo=`/root/bin/gam/gam info user ${userName}`
    checkGoogleVariables ${userInfo}
    OK 'Userinfo' ${userInfo}
}

function checkGoogleVariables(){
    local error="$@"
    if [[ ${error} =~ .*ERROR.* ]] ; then
        WARNING 'Something going wrong, error' "${error}"
        return 1
    fi
}

function selectGoogleGroups() {
    allGroups=(phpGroups dotnetGroups javascriptGroups androidGroups designGroups businessanalystsGroups iosGroups pmGroups hrGroups qaGroups salesGroups marketingGroups javaGroups)
    phpGroups=(all team-backend team-${location})
    dotnetGroups=(all team-dotnet team-${location})
    javaGroups=(all team-java team-${location})
    javascriptGroups=(all team-frontend team-${location})
    androidGroups=(all team-android team-${location})
    designGroups=(all team-design team-${location})
    businessanalystsGroups=(all team-businessanalysts team-${location})
    iosGroups=(all team-ios team-${location})
    pmGroups=(all team-pm team-${location})
    hrGroups=(all team-hr team-${location} team-hr-${location} talent)
    qaGroups=(all team-qa team-${location} )
    salesGroups=(all team-sales team-sales-${location})
    marketingGroups=(all team-marketing team-${location})
    for item in ${allGroups[@]}
        do
            if [[ "${item}" == "${userDepartment}Groups" ]] ; then
                selectedGroups="${item[@]}"
            fi
        done
    if [ -z ${selectedGroups} ] ; then
        WARNING 'Can'\''t select groups for input department' ${userDepartment}
    else
        NOTICE 'We select groups for user' ${userName}
    fi
}

function updateGoogleGroups(){
    eval aliasArray=\${"$selectedGroups[@]"}
    for item in ${aliasArray[@]}
        do
            updateGroup=`/root/bin/gam/gam update group ${item} add member ${userName}`
            checkGoogleVariables ${updateGroup}
            OK 'Add user to group' ${item}
        done
}

function createCrowdUser(){
    echo "
    {
       \"name\" : \"$NAME_LOWER.$SURNAME_LOWER\",
       \"first-name\" : \"$NAME\",
       \"last-name\" : \"$SURNAME\",
       \"display-name\" : \"$NAME $SURNAME\",
       \"email\" : \"$NAME_LOWER.$SURNAME_LOWER@yourdomain.com\",
       \"password\" : {
          \"value\" : \"$PASSWD\"
       },
       \"active\" : \"true\",
       \"attributes\" : {
          \"attributes\" : [
             {
                \"name\" : \"attr-name\",
                \"values\" : [
                   \"attr-value\"
                ]
             }
          ]
       }
    }" > $JSON

    curlStatus=`curl -s -q -XPOST -u "${cuser}:${upasswd}" "https://auth.yourdomain.info/crowd/rest/usermanagement/1/user" -H "Content-Type: application/json" -d@"${JSON}" -w ' %{http_code}'  | awk '{print $NF}'`
    if [ "${curlStatus}" != "201" ] ; then
        WARNING 'Can'\''t create user in Crowd app directory, responce code' "${curlStatus}"
         if [ "${curlStatus}" == "400" ] ; then
            OK 'MEMBERSHIP_ALREADY_EXISTS'
        fi
    else
        OK 'Create user in Crowd app directory'
    fi
}

function crowdGroup(){
    group='confluence-users'
    echo "
    {
        \"name\" : \"${group}\"
    }" > $JSON
    curlStatus=`curl -s -q -XPOST -u "${cuser}:${upasswd}"  https://auth.yourdomain.info/crowd/rest/usermanagement/1/user/group/direct?username="$NAME_LOWER.$SURNAME_LOWER"  -H 'Content-Type: application/json' -d@"$JSON" -w ' %{http_code}'  | awk '{print $NF}'`
    if [ "${curlStatus}" != "201" ] ; then
        WARNING 'Can'\''t add user in Crowd app group, responce code' "${curlStatus}"
        if [ "${curlStatus}" == "409" ] ; then
            OK 'MEMBERSHIP_ALREADY_EXISTS'
        fi
    else
        OK 'Add user to confluence-users group'
    fi
}

function createJiraUser(){
    echo "
    {
       \"name\" : \"$NAME_LOWER.$SURNAME_LOWER\",
       \"displayName\" : \"$NAME $SURNAME\",
       \"emailAddress\" : \"$NAME_LOWER.$SURNAME_LOWER@yourdomain.net\",
       \"password\" : \"$PASSWD\"

    }" > $JIRA_JSON
    curlStatus=`curl -q -s -XPOST -u "${jname}:${jpasswd}" "https://yourjiraportal.atlassian.net/rest/api/3/user" -H "Content-Type: application/json"  --cookie "${cookie}" -d@$JIRA_JSON -w ' %{http_code}' | awk '{print $NF}'`
    if [ "${curlStatus}" != "201" ] ; then
        WARNING 'Can'\''t create user in Jira, responce code' "${curlStatus}"
    else
        NOTICE 'Create user in Jira'
    fi
}

function jiraGroups(){
    if [ "${location}" == "kiev" ] ; then
        location="kyiv"
    fi
    if [ "${userDepartment}" == "marketing" ] ; then
        jiraGroups=(yourcompany-${location} team-marketing)
    elif [ "${userDepartment}" == "pm" ] ; then
        jiraGroups=(yourcompany-${location} team-yourcompany-projectmanagers)
    elif [ "${userDepartment}" == "hr" ] ; then
        jiraGroups=(yourcompany-${location} team-yourcompany-talent)
    else
        jiraGroups=(yourcompany-${location} team-yourcompany-${userDepartment})
    fi
        for group in ${jiraGroups[@]}
            do
                echo "
                {
                    \"name\" : \"$NAME_LOWER.$SURNAME_LOWER\"
                }" > $JSON
                curlStatus=`curl -u "${jname}:${jpasswd}" -q -s -XPOST "https://jiraportal.atlassian.net/rest/api/3/group/user?groupname=${group}"  -H "Content-Type: application/json"  --cookie "JSESSIONID=${cookie}" -d@$JIRA_JSON -w ' %{http_code}' | awk '{print $NF}'`
                if [ "${curlStatus}" != "201" ] ; then
                    WARNING 'Can'\''t add user in Jira group' ${group} ',responce code' "${curlStatus}"
                else
                    OK 'Add user to Jira group' ${group}
                fi
            done
}

function sendInviteToSlackChannel(){
    if [ "${location}" == "minsk" ] ; then
        channel_id_location="C4W1YDJJ2"
    elif [ "${location}"] == "kiyv" ] ; then
        channel_id_location="C4TBXV8CW"
    fi
    curlStatus=`curl -q -s -XPOST "https://slack.com/api/users.admin.invite?token=${slack_token}&email=${userName}@yourcompany.net&channels=C04HUPFEK,${channel_id_location}"`
    if [[ ! "${curlStatus}" =~ .*true.* ]] ; then
        WARNING 'Can'\''t send invite to user' ${userName} ',responce code' "${curlStatus}"
    else
        OK 'Slack invite to channel general was send'
    fi
}

function sendEmailTo(){
    NOTICE 'Whom send credentials to?'
    NOTICE 'Enter your `name.surname`. You will receive email with user credentials.'
    read recipient
    recipient=${recipient:?"Missing recipient"}
}

function sendEmailToEmployee() {
    sendEmail -f ${uname}@yourcompany.net \
    -t ${EMAIL} -bcc $tempomanager@yourcompany.net, $1@yourcompany.net -u "yourcompany | First letter" -o message-file="${SEND}" \
    -o message-content-type=html -s smtp.gmail.com:587 -xu ${maillogin}@yourcompany.net -xp ${mailpasswd} 1>${sendEmailFile}
    result=`grep -q 'successfully' ${sendEmailFile} | echo $?`
    if [[ $result -eq 0 ]] ; then
        OK 'Email to '$NAME_LOWER.$SURNAME_LOWER'; bcc to '${tempomanager}'; bcc to '${1}' was sent successfully'
    else
        WARNING 'Can'\''t send email to user'
    fi
}

source .config || ERROR 'Can'\''t load config file'
[ "$UID" -ne "0" ] && { ERROR "$0 must be run as root"  ;}

./mail/header.sh
prepare
createGoogleUser
createCrowdUser
crowdGroup
createJiraUser
jiraGroups
./mail/footer.sh
sendInviteToSlackChannel
sendEmailTo
sendEmailToEmployee ${recipient}

