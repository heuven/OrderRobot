*** Settings ***
Documentation   Orders robots from RobotSpareBin Industries Inc.
...             Saves the order HTML receipt as a PDF file.
...             Saves the screenshot of the ordered robot.
...             Embeds the screenshot of the robot to the PDF receipt.
...             Creates ZIP archive of the receipts and the images.
Library         RPA.Browser.Selenium
Library         RPA.HTTP
Library         RPA.Tables
Library         RPA.PDF
Library         RPA.Robocloud.Secrets
Library         RPA.FileSystem
Library         RPA.Archive
Library         RPA.Dialogs


*** Keywords ***
Open the robot order website
    ${website}=     Get Secret    robotsparebin
    Open Available Browser    ${website}[url]
    Maximize Browser Window


*** Keywords ***
Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders}=    Read table from CSV    ${CURDIR}${/}orders.csv    
    [return]  ${orders}

# +
*** Keywords ***
Fill the form    
    [Arguments]    ${order}
    Select From List By Value    id:head    ${order}[Head]
    Click Element    id-body-${order}[Body]
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${order}[Legs]
    Input Text    id:address    ${order}[Address]

    
# -

*** Keywords ***
Close the annoying modal
        Click Button    OK

*** Keywords ***
Close The Browser
    Close Browser

*** Keywords ***
Preview the robot
    Click Button    id:preview

*** Keywords ***
Submit the order
    Click Button    id:order
    Wait Until Element Is Visible    id:order-completion

*** Keywords ***
Submit the order and check for success
    Wait Until Keyword Succeeds     1 min   1 sec  Submit the order

*** Keywords ***
Take a screenshot of the robot      
    [Arguments]    ${order_number}
    Screenshot  id:robot-preview-image  ${CURDIR}${/}images${/}{order_number}.png
    [return]  ${CURDIR}${/}images${/}{order_number}.png

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${receipt_data}=  Get Element Attribute  id:order-completion  outerHTML
    Html To Pdf  ${receipt_data}  ${CURDIR}${/}receipts${/}${order_number}.pdf
    [return]  ${CURDIR}${/}receipts${/}${order_number}.pdf

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}   ${pdf}
    Open Pdf       ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Close Pdf      ${pdf}

*** Keywords ***
Cleanup directories
    ${receipt_folder}=  Does Directory Exist  ${CURDIR}${/}receipts
    ${images_folder}=  Does Directory Exist  ${CURDIR}${/}images
    Run Keyword If  '${receipt_folder}'=='True'     Remove Directory  ${CURDIR}${/}receipts  True
    Run Keyword If  '${images_folder}'=='True'     Remove Directory  ${CURDIR}${/}images  True

*** Keywords ***
Create a ZIP file of the receipts
     Archive Folder With Zip    ${CURDIR}${/}receipts  ${CURDIR}${/}output${/}receipts.zip
     Cleanup directories

*** Keywords ***
Go to order another robot
    Click Button    id:order-another

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Cleanup directories
    
    Create Directory    ${CURDIR}${/}images
    Create Directory    ${CURDIR}${/}receipts
    Create Directory    ${CURDIR}${/}output
    
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order and check for success
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close The Browser

