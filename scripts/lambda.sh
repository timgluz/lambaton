CONFIG_FILE=lambda_configs.json

function create_role_fn(){
  local role_file="file://$(pwd)/scripts/default-iam-role.json"
  local policy_file="file://$(pwd)/scripts/default-iam-policy.json"
  local role_name="$1"

  if [ -n "$role_name" ]; then
    echo "Creating a new IAM role for Lambda service"
    aws iam create-role --role-name "$role_name" \
      --assume-role-policy-document $role_file
   
    #attach policy for a new file
    aws iam put-role-policy --role-name "$role_name" \
      --policy-name LambdaDefaultPolicy \
      --policy-document $policy_file

  else
    echo "$0 : role_name is missing"
  fi
}

function create_fn(){
  local fn_name="$1"
  local handler="$2"

  if [[ -n "$fn_name"  && -n "$handler" ]]; then
    echo "Creating a new lambda function ${handler}/${fn_name}"
    aws lambda create-function \
      --region $region \
      --handler "$handler" \
      --function-name "$fn_name" \
      --zip-file "$zipfile" \
      --role $role \
      --runtime $runtime \
      --timeout $timeout \
      --memory-size $memory
  else
    echo "$0: missing fn-name or handler:, arg1: $fn_name, arg2: $handler"
  fi

}

function update_fn(){
  local fn_name="$1"

  if [ -n "$fn_name" ]; then
    echo "Updating a lambda fn: ${fn_name}"
    aws lambda update-function-code \
      --function-name ${fn_name} \
      --zip-file ${zipfile}
  else
    echo "$0: function name is missing"
  fi
}

function invoke_fn(){
  local fn_name="$1"
  local payload="$2"
  local outfile="lambda_result.txt"

  if [ -n "$fn_name" ]; then
    echo "Invoking a lambda fn: ${fn_name}"
    aws lambda invoke --function-name "${fn_name}" --payload "${payload}" $outfile
    cat $outfile
    rm -d $outfile
  else
    echo "$0: function or payload missing"
  fi
}

function usage(){
  echo "Simpleton Agent for AWS Lambda"
  echo "prerequisites: aws-cli, jq"
  echo "-----------------------------------------------------------------------"
  echo "Available commands:"
  echo "> create_role DefaultLambdaRole2" - creates a role for Lambda services
  echo "> create <function-name> <handler> - creates a new lambda function"
  echo "> update <function-name> - deploys a new version of lambda command"
  echo "> invoke <function-name> <payload> - invokes function with JSON file"
  echo "> usage"
}

function jq_match(){
  cat $CONFIG_FILE | jq -r $1
}

function list_functions(){
  printf '%s\n' "${fns[@]}"
}

function load_settings(){
  runtime=$(jq_match '.runtime')
  timeout=$(jq_match '.timeout')
  memory=$(jq_match '."memory-size"')
  region=$(jq_match '.region')
  role=$(jq_match '.role')
  zipfile="fileb://$(pwd)/$(jq_match '."zip-file"')"
  fns=( $(jq_match '.functions') )

}

function update_all(){
  local fn_parts=()
  local fn_names=$(jq_match '.functions|keys')

  #echo $fn_names
  for fn_name in $fn_names
  do
    if [ -n $fn_name ] && [ $fn_name != "[" ] && [ $fn_name != "]"  ]
    then
      update_fn ${fn_name//[-+=.,\"]/} #remove not allowed characters from name
    fi
  done
}

function show_configs(){
  echo "Settings from $CONFIG_FILE: "
  echo "runtime: $runtime"
  echo "timeout: $timeout"
  echo "memory: $memory"
  echo "region: $region"
  echo "role: $role"
  echo "zip-file: $zipfile"
  echo "functions: ${fns[@]}"
}


load_settings
case $1 in
  "create"     ) create_fn $2 $3;;
  "create_role" ) create_role_fn $2;;
  "update"     ) update_fn $2;;
  "update_all" ) update_all;;
  "invoke"     ) invoke_fn $2 $3;;
  "configs"    ) show_configs;;
  *            ) usage;;
esac
