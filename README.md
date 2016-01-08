#Lambaton

It's simplified command-line util for AWS Lambda to make command-line hacking more fun and to simplify build tasks;


## Requirements

It requires `aws-cli` and `jq` and correct values in the `lambda_configs.json` file.

You can use the `create_role` command to create a role with correct policy to execute Lambda functions. Just run the command with profile name and copy the value of "Arn" field into a :role field in the `lambda_configs.json` file.


## Commands

* **create_role** *role_name* - creates a new AWS role with meaningful name 

* **create** *function_name* *handler-name* - a creates a new Lambda function

```
$> ./lambda.sh create hello2 world.cmd.Hello2
``` 

where handler_name matches to class name in project. For example Clojure's Lambada

```
(deflambdafn world.cmd.Hello2
	[in-fd out-file-fd context]
	...)
```

* **update** *function_name* - updates an existing lambda function

```
$> ./lambda.sh update hello2
```

* **update_all** - updates all the functions defined in the `lambda_configs.json`. I'm not sure how helpful it is and it may change;


* **invoke** *function_name* *payloadJSON* - invokes lambda function and prints out content of result file;