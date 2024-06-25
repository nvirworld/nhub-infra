import json
import os
import urllib.request

def lambda_handler(event, context):
    if 'Records' not in event or len(event['Records']) == 0:
        return {
            'statusCode': 400,
            'body': 'No Records found in event'
        }
    
    print(json.dumps(event))
    records = event['Records']
    for record in records:
        message = record['Sns']['Message']
        parsed_message = json.loads(message)
        
        slack_webhook_url = os.environ['SLACK_WEBHOOK_URL']
        slack_channel = os.environ['SLACK_CHANNEL']

        detail = parsed_message.get('detail', {})
        slack_message = f"{detail.get('pipeline')} | {detail.get('stage')} | {detail.get('state')}"
        slack_payload = {
            'channel': f'#{slack_channel}',
            'text': f"{slack_message}"
        }
        # ```{json.dumps(parsed_message, indent=4)}```
        
        request = urllib.request.Request(
            slack_webhook_url,
            data=json.dumps(slack_payload).encode('utf-8'),
            headers={'Content-Type': 'application/json'}
        )
        
        with urllib.request.urlopen(request) as response:
            print(response.read().decode('utf-8'))
        
    return {
        'statusCode': 200
    }

