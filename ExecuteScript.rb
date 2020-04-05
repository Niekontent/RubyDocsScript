require "google/apis/script_v1"
require "googleauth"
require "googleauth/stores/file_token_store"
require "fileutils"

FOLDER_ID =''.freeze
DOC_FILE_ID = ''.freeze
TEXT_TO_REPLACE = ''.freeze
NEW_TEXT = ''.freeze
SCRIPT_ID = ''.freeze

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

request = Google::Apis::ScriptV1::ExecutionRequest.new(
    function: "replacingFunction", parameters: [FOLDER_ID, DOC_FILE_ID, TEXT_TO_REPLACE, NEW_TEXT]
)

service.run_script SCRIPT_ID, request