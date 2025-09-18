#!/bin/bash

#===== constants =====
WINDOW_HEIGHT=20
WINDOW_WIDTH=60
ERROR_EXPRESSION_TYPE="\nThe expression is not valid.\nPlease enter a valid expression."
ERROR_EXPRESSION_EMPTY="\nThe expression is empty.\nPlease enter a valid expression."
GITHUB_PROFILE="https://github.com/marchesinia187179"
MAX_EXPRESSION_LENGTH=`ulimit -s`

#===== pages functions =====
function showHomePage {
    dialog \
    --title "Calculator" \
    --yes-label "Start" \
    --no-label "Exit" \
    --extra-button --extra-label "Credits" \
    --yesno "\n> Hi $1,\nThis is a simple calculator written entirely in bash." \
    $WINDOW_HEIGHT $WINDOW_WIDTH

    return $?
}

function showCreditsPage {
    dialog \
    --title "Credits" \
    --yes-label "Back" \
    --no-label "GitHub Profile" \
    --yesno "\nDeveloped by Marchesini Alessandro\nCalculator v1.0.0" \
    $WINDOW_HEIGHT $WINDOW_WIDTH
    
    return $?
}

function showEnterExpressionPage {
    expression=$(dialog \
    --stdout \
    --title "Enter Expression" \
    --cancel-label "Exit" \
    --extra-button --extra-label "Info" \
    --form "\nUse these operators without spaces:\n+ - * / sqrt(n) ^ e(n) l(n)/l(b)\n< > << >> == != && ||\n( )" $WINDOW_HEIGHT $WINDOW_WIDTH 0 \
    "" 1 1 "" 0 0 $MAX_EXPRESSION_LENGTH 0)

    return $?
}

function showInfoPage {
    dialog --title "Info" --textbox "info.txt" $WINDOW_HEIGHT $WINDOW_WIDTH
    
    return $?
}

function showErrorPage {
    dialog --title "Error" --msgbox "$errorMsg" $WINDOW_HEIGHT $WINDOW_WIDTH
    
    return $?
}

function showResultPage {
    dialog \
    --title "Result" \
    --yes-label "New calculation" \
    --no-label "Exit" \
    --extra-button --extra-label "History" \
    --yesno "\nExpression: $1\nResult: $2\n" \
    $WINDOW_HEIGHT $WINDOW_WIDTH

    return $?
}

function showHistoryPage {
    dialog --title "History" --textbox "history.txt" $WINDOW_HEIGHT $WINDOW_WIDTH
    
    return $?
}

#===== validator functions =====
function isExpressionValid {
    #empty expression error
    if [ -z "$expression" ]
    then    errorMsg=$ERROR_EXPRESSION_EMPTY
            return 1
    fi

    #no characters permitted error
    case $expression in
    *[!0-9\+\-\*\/\<\>\=\!\&\|\(\)\^\s\q\r\t\e\l]*)     errorMsg=$ERROR_EXPRESSION_TYPE
                                                        return 1;;
    esac
    
    #syntax error
    if [ -z "$(echo "$expression" | bc -l)" ]
    then    errorMsg=$ERROR_EXPRESSION_TYPE
            return 1
    fi
    
    return 0
}

#===== others functions =====
function openGitHub {
    if command -v xdg-open >/dev/null
    then    xdg-open "$GITHUB_PROFILE" >/dev/null 2>&1 &
    elif command -v open >/dev/null
    then    open "$GITHUB_PROFILE" >/dev/null 2>&1 &
    fi
}

function resetHistoryAndEnvironment {
    unset expression
    unset errorMsg
    > history.txt
}

#===== main =====
export expression
export errorMsg
> history.txt

while true; do
    showHomePage `whoami`
    case $? in
    1)  #exit button pressed
        resetHistoryAndEnvironment
        exit;;
    3)  #credits button pressed
        showCreditsPage
        [ $? == 1 ] && openGitHub;;
    0)  #start button pressed
        while true; do
            showEnterExpressionPage
            case $? in
            0)  #ok button pressed
                break;;
            1)  #exit button pressed
                resetHistoryAndEnvironment
                exit;;
            3)  #info button pressed
                showInfoPage;;
            esac
        done
        
        #check errors
        isExpressionValid
        case $? in
        1)  #errors detected
            showErrorPage;;
        0)  #no errors
            result=$(echo "$expression" | bc -l)
            printf "%s = %s\n\n" "$expression" "$result" >> history.txt
            showResultPage "$expression" "$result"
            
            case $? in
            1)  #exit button pressed
                resetHistoryAndEnvironment
                exit;;
            3)  #history button pressed
                showHistoryPage;;
            esac;;
        esac;;
    esac
done
