# WOFOST AWS Lambda Function









## R Documentation

- [CRAN WOFOST](https://cran.r-project.org/web/packages/Rwofost/index.html)
- [WOFOST Reference Manual](https://cran.r-project.org/web/packages/Rwofost/Rwofost.pdf)

## Input JSON

The input JSON consists of 4 fields:

1. "file_url" : A url  is provided for the input file to be used from the WOFOST function.
2. "control_params" : A list of the parameters of the function *wofost_control()*. Refer to the documentation as to which are these parameters and what are the values to be assigned.
3. "crop" : The crop which is selected to be analyzed by the WOFOST function.
4. "soil" : The soil type which is selected to be used in the analysis by the WOFOST function.

Example of input JSON:

~~~json
{
	"file_url" : "https://r-lambdas-dummy.s3.eu-central-1.amazonaws.com/weather_example.csv",
	"control_params" : {
		"modelstart" : "1978-02-06",
		"latitude" : 52.57,
		"elevation" : 50,
		"CO2" : 360,
		"cropstart" : 0,
		"water_limited" : 0,
		"watlim_oxygen" : 0,
		"start_sowing" : 0,
		"max_duration" : 365,
		"stop_maturity" : 1
	},
	"crop" : "barley",
	"soil" : "ec1"
}
~~~

## Using the Lambda Function in R

The proper way to use the Lambda function through an R script is shown below:

~~~R
## required libraries
library("httr")
library("jsonlite")

##1st way to send data, with a URL of the json file

post_input_json = "https://r-lambdas-dummy.s3.eu-central-1.amazonaws.com/wofost_input_json.json"

##2nd way to send data, loading from local json file and converting it to the appropriate format for the POST call

input_local_file_path = "wofost_input_json.json" #provide the correct path to JSON
input_json = fromJSON(input_local_file_path)
post_input_json = toJSON(input_json)

##create the headers for the POST call

header = add_headers(.headers = c('Authorization'= 'sc10_lambda_auth', 'Content-Type' = 'application/json'))

##execute the POST call

response = POST(url = "https://lambda.wofost.scio.services", config = header , body = post_input_json)

##get the returned data as a R list

data_list = content(response)

##get the returned data as a json variable (can be saved as local json file)

data_json = toJSON(data_list)
~~~

## Output

The response of a successful run of the lambda function should look like the example below. More specifically, the response is containing the result of the WOFOST *wofost_model run()*. In detail, the function's output is a R Dataframe which is converted to a JSON. Each field in this JSON is a row of the R Dataframe.

~~~json
[
  {
    "date": "1978-02-06",
    "step": 1,
    "TSUM": 0,
    "DVS": 0,
    "LAI": 0.048,
    "WRT": 36,
    "WLV": 24,
    "WST": 0,
    "WSO": 0,
    "TRA": 0.0001,
    "EVS": 0.0019,
    "EVW": 0,
    "SM": 0.11
  },
  {
    "date": "1978-02-07",
    "step": 2,
    "TSUM": 1.75,
    "DVS": 0.0022,
    "LAI": 0.048,
    "WRT": 36,
    "WLV": 24,
    "WST": 0,
    "WSO": 0,
    "TRA": 0.0007,
    "EVS": 0.0073,
    "EVW": 0,
    "SM": 0.11
  },
  {
    "date": "1978-02-08",
    "step": 3,
    "TSUM": 1.75,
    "DVS": 0.0022,
    "LAI": 0.048,
    "WRT": 36,
    "WLV": 24,
    "WST": 0,
    "WSO": 0,
    "TRA": 0.0002,
    "EVS": 0.0017,
    "EVW": 0,
    "SM": 0.11
  }
  ...
]
~~~

In the section "Using the Lambda Function in R" , it is shown how to obtain the output as a R list or as a JSON.



## Deployment

![](https://scio-images.s3.us-east-2.amazonaws.com/wofost.png)

### Prerequistes

- AWS Account
- AWS CLI
- Node.js
- Python
- AWS CDK Toolkit
- Docker

The AWS services that are being used are the the ones below:

- CloudFormation
- Lambda
- Elastic Container Registry
- API Gateway

Those are being combined by utilizing AWS Cloud Development Kit (CDK), a software development framework for defining cloud infrastructure in code and provisioning it through AWS CloudFormation.

You can read more about AWS CDK in its official documentation page and you can also the below relevant workshop to get you started.

[What is the AWS CDK?](https://docs.aws.amazon.com/cdk/latest/guide/home.html)

[AWS CDK Workshop](https://cdkworkshop.com/)

We are using Python as our code hence all the workflow will be demonstrated with it. 

The steps are not different if you are using any other language that the toolkit supports although relevant debugging will be needed from the code's perspective.

First, you will need to generate AWS access keys. Make sure that the user account that will be used has IAM permissions for access to the resources and services mentioned.

Once you have generated the keys, you may install AWS CLI and add them to your machine.

You can read more in the official documentation for its installation and configuration.

[AWS Command Line Interface documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html)



Once you have this set up, you may proceed with the below steps.

```bash
# Installation of CDK toolkit
npm install -g aws-cdk@1.85.0

# Confirm successful installation of CDK
cdk version 

# Creating virtual environemnt for Python
python3 -m venv .venv 

# Activating the virtual environment for CDK
source .venv/bin/activate 

# Installing Python CDK dependencies 
pip3 install -r requirements.txt 
```



Now you can deploy by using CDK.

```bash
# Getting AWS account information for CDK
ACCOUNT_ID=$(aws sts get-caller-identity --query Account | tr -d '"')
AWS_REGION=$(aws configure get region)

# Deploying
cdk bootstrap aws://${ACCOUNT_ID}/${AWS_REGION}
cdk deploy --require-approval never
```

With `cdk bootstrap` command, a CloudFormation stack is creating based on the `app.py`.  

Then with `cdk deploy` the resources of the CloudFormation stack are being created and deployed. This process will take time as the container is being built and the completion is depending  and in the internal operations of the container (installing and running the needed dependencies as those are defined in the Dockerfile) and on the resources of the host machine.

Afterwards, the container will be pushed to AWS ECR (Elastic Container Registry) which is the container registry service of AWS. This will take some time as well as it depends on the internet connection you have.



Once the above complete, you may navigate to API Gateway service from the AWS console and you will find the API with the name "wofost-lambda". The name of the API, lambda function & container is being set in the *app.py* (line 13).

You will then see URL that has been created in the form of:

 `https://<random text>.execute-api.< your aws region>>.amazonaws.com`

The lambda function is now ready to be used! 

Fore more detailed information about the ecosystem, you may check [this article](https://medium.com/swlh/deploying-a-serverless-r-inference-service-using-aws-lambda-amazon-api-gateway-and-the-aws-cdk-65db916ea02c).