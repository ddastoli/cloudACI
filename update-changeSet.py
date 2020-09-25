#! /usr/local/bin/python3

## CREDENTIALS OF ALL THE STUDENTS ARE PRESENT IN /Users/ddastoli/.aws/credentials  OR POINT TO THE RIGHT CREDENTIALS FILE USING THE ENVIRONMENT VARIABLES
### THIS SCRIPT WILL UPLOAD CS TEMPLATES IN ALL 30 AWS ACCOUNTS.
#
# RUN THIS SCRIPT IN PYTHON3 ENVIRONMNT WITH BOTO3 Installed
#
#

import boto3


######REGION NAME
#regionname = 'us-east-1'
regionname = 'eu-west-2'
#regionname = 'us-east-2'

### LIST OF ALL STUDENT ACCOUNTS STUDENT 1-35
studentnames = ["clstudent1","clstudent2","clstudent3","clstudent4","clstudent5","clstudent6","clstudent7","clstudent8","clstudent9","clstudent10","clstudent11","clstudent12","clstudent13","clstudent14","clstudent15","clstudent16","clstudent17","clstudent18","clstudent19","clstudent20","clstudent21","clstudent22","clstudent23","clstudent24","clstudent25","clstudent26","clstudent27","clstudent28","clstudent29","clstudent30","clstudent31","clstudent32","clstudent33","clstudent34","clstudent35"]



for student in studentnames:

    ##### CREATING ACCOUTN SESSION
    session = boto3.session.Session(profile_name=student)
    boto3.setup_default_session(profile_name=student)
    print('  ')
    print("############# LIST OF CLOUD FORMATION Templates FOR ACCOUNT",student)
    client = boto3.client('cloudformation',region_name =regionname)
    cloudformation = boto3.resource('cloudformation',region_name =regionname)
    URL = 'https://domcisco.s3.eu-west-2.amazonaws.com/tenant-cft.json'
        
    for stack in cloudformation.stacks.all():
      print (stack.name)
      print (client.list_change_sets(StackName=stack.name))
      try:
        CS = client.create_change_set(
          StackName=stack.name,
          TemplateURL=URL,
          Capabilities=[
            'CAPABILITY_NAMED_IAM',
          ],
          ChangeSetName='CS'
        )
      except client.exceptions.AlreadyExistsException:
        print('could not upload CS')
      try:
        client.execute_change_set(ChangeSetName='CS',StackName=stack.name)
      except client.exceptions.InvalidChangeSetStatusException:
        print('CS is invalid')

      #stackpolicy = client.get_stack_policy('Tn19Pod1')
    #print (stackpolicy)

    #print(response)
    print("############")
    print()

