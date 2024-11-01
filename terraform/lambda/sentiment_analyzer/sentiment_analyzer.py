import boto3
import csv
import io
import json
import os
from datetime import datetime

s3 = boto3.client('s3')


def get_latest_file(bucket, prefix):
    try:
        files = s3.list_objects_v2(Bucket=bucket, Prefix=prefix)
        if 'Contents' not in files or not files['Contents']:
            raise ValueError(f"No files found in bucket {bucket} with prefix {prefix}")
        return max(files['Contents'], key=lambda x: x['LastModified'])
    except Exception as e:
        print(f"Error in get_latest_file: {str(e)}")
        raise


def get_file_content(bucket, key):
    try:
        print(f"Reading file: {key}")
        response = s3.get_object(Bucket=bucket, Key=key)
        content = response['Body'].read().decode('utf-8')
        return json.loads(content)
    except Exception as e:
        print(f"Error reading file: {str(e)}")
        raise


def save_comprehend_format(bucket, data):
    try:
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"comprehend_training_data_{timestamp}.csv"
        key = f"processed_data/{filename}"

        # Create CSV in memory
        output = io.StringIO()
        writer = csv.writer(output, quoting=csv.QUOTE_MINIMAL)
        
        # Write header - EXACTLY these two columns for Comprehend
        writer.writerow(['label', 'text'])
        
        # Write data rows
        for entry in data:
            # Ensure text doesn't contain newlines or other problematic characters
            cleaned_text = entry.get('text', '').replace('\n', ' ').replace('\r', ' ').strip()
            label = entry.get('label', '').strip()
            
            # Skip empty entries
            if not cleaned_text or not label:
                continue
                
            writer.writerow([label, cleaned_text])

        # Upload to S3
        s3.put_object(
            Bucket=bucket,
            Key=key,
            Body=output.getvalue(),
            ContentType='text/csv'
        )
        print(f"Successfully saved Comprehend training data to {key}")
        return key
        
    except Exception as e:
        print(f"Error saving Comprehend format: {str(e)}")
        raise


def lambda_handler(event, context):
    try:
        bucket = os.environ['S3_BUCKET']
        print(f"Starting processing for bucket: {bucket}")

        # Get latest Reddit data
        reddit_prefix = 'raw_data/reddit/'
        latest_reddit_file = get_latest_file(bucket, reddit_prefix)
        reddit_data = get_file_content(bucket, latest_reddit_file['Key'])

        # Validate data structure
        if not isinstance(reddit_data, list):
            raise ValueError("Input data must be a list of objects")

        # Save in Comprehend format
        output_key = save_comprehend_format(bucket, reddit_data)

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Data processed successfully for Comprehend',
                'output_file': output_key,
                'entries_processed': len(reddit_data)
            })
        }

    except Exception as e:
        print(f"Error in lambda_handler: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e),
                'message': 'Error processing data for Comprehend'
            })
        }