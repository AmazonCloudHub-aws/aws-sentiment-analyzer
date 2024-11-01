import praw
import boto3
import json
import os
from datetime import datetime

# Set up Reddit API connection
reddit = praw.Reddit(
    client_id=os.environ['REDDIT_CLIENT_ID'],
    client_secret=os.environ['REDDIT_CLIENT_SECRET'],
    user_agent="MyAPI/0.0.1"
)

# Set up AWS S3 client
s3 = boto3.client('s3')


def lambda_handler(event, context):
    # Define the subreddit to collect data from
    subreddit = reddit.subreddit('technology')
    hot_posts = subreddit.hot(limit=100)
    
    # Prepare a list to hold processed posts
    posts = []

    for post in hot_posts:
        # Combine the title and the body text (selftext)
        post_text = post.title + " " + post.selftext
        
        # Placeholder label (adjust as needed)
        label = "neutral"  # You can replace this with actual labels later
        
        # Append the post text and label to the list
        posts.append({
            'text': post_text,  # The content of the post
            'label': label      # Placeholder label
        })
    
    # Create a filename with the current timestamp
    filename = (
        f"reddit_data_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    )
    
    # Save the file to S3 in the desired bucket
    s3.put_object(
        Bucket=os.environ['S3_BUCKET'],
        Key=f"raw_data/reddit/{filename}",
        Body=json.dumps(posts)  # Convert the list of posts to JSON format
    )
    
    # Return a success message with the number of posts collected
    return {
        'statusCode': 200,
        'body': json.dumps(f'Collected {len(posts)} posts from Reddit')
    }
