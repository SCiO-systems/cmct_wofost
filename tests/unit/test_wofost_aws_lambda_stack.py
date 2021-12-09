import json
import pytest

from aws_cdk import core
from wofost_aws_lambda.wofost_aws_lambda_stack import WofostAwsLambdaStack


def get_template():
    app = core.App()
    WofostAwsLambdaStack(app, "wofost-aws-lambda")
    return json.dumps(app.synth().get_stack("wofost-aws-lambda").template)


def test_sqs_queue_created():
    assert("AWS::SQS::Queue" in get_template())


def test_sns_topic_created():
    assert("AWS::SNS::Topic" in get_template())
