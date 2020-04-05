require "google/apis/script_v1"
require "googleauth"
require "googleauth/stores/file_token_store"
require "fileutils"

OOB_URI = "urn:ietf:wg:oauth:2.0:oob".freeze
APPLICATION_NAME = "Google Docs Ruby".freeze
CREDENTIALS_PATH = "credentials.json".freeze
TOKEN_PATH = "token.yaml".freeze
SCOPE = ["https://www.googleapis.com/auth/script.projects",
          "https://www.googleapis.com/auth/documents",
          "https://www.googleapis.com/auth/drive"].freeze

def authorize
  client_id = Google::Auth::ClientId.from_file CREDENTIALS_PATH
  token_store = Google::Auth::Stores::FileTokenStore.new file: TOKEN_PATH
  authorizer = Google::Auth::UserAuthorizer.new client_id, SCOPE, token_store
  user_id = "default"
  credentials = authorizer.get_credentials user_id
  if credentials.nil?
    url = authorizer.get_authorization_url base_url: OOB_URI
    puts "Open the following URL in the browser and enter the " \
         "resulting code after authorization:\n" + url
    code = gets
    credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI
    )
  end
  credentials
end

service = Google::Apis::ScriptV1::ScriptService.new
service.client_options.application_name = APPLICATION_NAME
service.authorization = authorize

request = Google::Apis::ScriptV1::CreateProjectRequest.new(
    title: "My Script"
)
resp = service.create_project request

script_id = resp.script_id
content = Google::Apis::ScriptV1::Content.new(
    files:     [
        Google::Apis::ScriptV1::File.new(
            name:   'replacingFunction',
            type:   "SERVER_JS",
            source: "function replacingFunction(folderID, docFileID, textToReplace, newText)" +
                "{\n var folder = DriveApp.getFolderById(folderID);\n" +
                "\n var existingFile = DriveApp.getFileById(docFileID);\n" +
                "\n var newFileID = existingFile.makeCopy(existingFile.getName(),folder).getId();\n" +
                "\n var newFileDoc = DocumentApp.openById(newFileID);\n" +
                "\n var newFileDocBody = newFileDoc.getBody();\n" +
                "\n newFileDocBody.replaceText(textToReplace, newText);\n" +
                "\n newFileDoc.saveAndClose();\n}"
        ),
        Google::Apis::ScriptV1::File.new(
            name:   "appsscript",
            type:   "JSON",
            source: "{\"timeZone\":\"America/New_York\",\"exceptionLogging\": \
            \"CLOUD\"}"
        )
    ],
    script_id: script_id
)
service.update_project_content script_id, content
puts "Add this script to your GCP project: https://script.google.com/d/#{script_id}/edit"
puts "Do not forget to deploy as API executable"
