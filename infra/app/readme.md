# Docuseal

Docuseal relies on a database and database user being created in order for it to store its metadata. Additionally, in order to use S3 as a storage solution for the uploaded and generated files, it requires an IAM User's Security Credentials with a policy to grant it read/write access to the bucket.

**Both access resources must be in place before deploying the app to the cluster.**

It's best practive **not** to store security credentials of any kind in a terraform statefile. Because of this, the process below outlines how to create an IAM user, generate security creds, and store them in a secret for the pod to use when deployed to the cluster.

## Creating the API token

Once the docuseal app is deployed and running, setup the initial user and save the credentials somewhere secure.

Navigate through the settings and copy the API token from this page: https://docuseal.dev.goflip.ai/settings/api

Use the following aws cli commands to create and save it to a secret so the external secrets operator can sync it into the cluster for the API to pick up and use

1. **Create the secret**
  ```sh
  aws secretsmanager create-secret --name dev-docuseal-api-token --profile flip
  ```

## Creating an IAM User and Access Keys for S3 Access

To provision AWS credentials for Docuseal using the `flip` profile:

1. **Create the IAM user:**
   ```sh
   aws iam create-user --user-name docuseal-app --profile flip
   ```

1. **Create the IAM Policy:**
  ```sh
  aws iam create-policy \
    --policy-name docuseal-s3-read-write \
    --policy-document file://./policies/s3ReadWrite.json \
    --profile flip
  ```

1. **Attach the required S3 policy:**
  * Modify the policy file as needed to set the correct partition and bucket prefix patterns
  ```sh
  aws iam attach-user-policy \
    --user-name docuseal-app \
    --policy-arn "arn:aws-us-gov:iam::358252705848:policy/docuseal-s3-read-write" \
    --profile flip
  ```

1. **Create access keys for the user:**
  ```sh
  aws iam create-access-key --user-name docuseal-app --profile flip
  ```
  * Copy the `AccessKeyId` and `SecretAccessKey` from the output and store them securely.
  * Save them to a local file temporarily called `creds.json` using the following format:
    ```json
    {
      "AccessKeyId": "AKIA******",
      "SecretAccessKey": "******",
    }
    ```

1. **Create an AWS Secrets manager secret:**
  ```sh
  aws secretsmanager create-secret --name dev-docuseal-s3-creds --profile flip
  ```
  * The `dev-` prefix is important because the External Secret Operator in the cluster is only permitted to access secrets with that prefix.

1. **Update the secret to set the value:**
  ```sh
  aws secretsmanager put-secret-value --secret-id dev-docuseal-s3-creds --secret-string file://creds.json --profile flip
  ```
  * Confirm in AWS Web Console the secret is configured as expected
  * Once confirmed, delete the local temporary `creds.json` file so it's not accidentally committed to the repo
