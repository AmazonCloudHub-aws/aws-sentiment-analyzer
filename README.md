# AWS Sentiment Analysis Pipeline

## Overview

This repository contains an automated sentiment analysis pipeline built on AWS, designed to process and analyze customer feedback from multiple sources. The project leverages AWS services (Lambda, S3, Comprehend) and Terraform for infrastructure as code.

## Key Features

- **Multi-Source Data Collection**: 
  - Reddit API integration
  - Amazon Customer Reviews Dataset processing

- **AWS-Powered Analysis**:
  - Sentiment analysis using Amazon Comprehend
  - Automated data processing with AWS Lambda
  - Scalable data storage in Amazon S3

- **Infrastructure Management**:
  - Infrastructure as Code using Terraform
  - Easy deployment and scaling

- **Visualization**:
  - Data insights through Amazon QuickSight

## Use Case

This project is ideal for businesses and researchers looking to gain insights from diverse customer feedback sources. It demonstrates:

- Cloud-based natural language processing
- Data engineering best practices
- Infrastructure automation

## Getting Started

1. Clone this repository
2. Follow the setup instructions in [SETUP.md](SETUP.md)
3. Configure your AWS credentials
4. Run Terraform to deploy the infrastructure

## Project Structure

```
.
├── terraform/           # Terraform configuration files
├── lambda/              # Lambda function code
│   ├── reddit_collector/
│   └── sentiment_analyzer/
├── scripts/             # Utility scripts
├── docs/                # Documentation
└── README.md            # This file
```

## Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Reddit API for providing access to public discussions
- Amazon Web Services for their comprehensive cloud offerings
- Open-source community for various tools and libraries used in this project

## Tags

#AWS #SentimentAnalysis #NLP #Terraform #DataEngineering #Python #Lambda
