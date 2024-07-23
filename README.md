# WarpStream BYOC Deployment Demo

## Prerequisites
- The AWS CLI tool.
- A running Elastic Kubernetes Service cluster and familiarity managing EKS clusters.
- A shell session that is authenticated into the same AWS account as the running EKS cluster.

## Walkthrough

Clone this repository and navigate to its directory in order to use the files that support this demo.

`git clone https://github.com/warpstreamlabs/warpstream-byoc-demo.git && cd -`

### Part I. Set up dependencies

In addition to the Kubernetes cluster in which the agent will run, BYOC deployment requires an S3 bucket for the agent to use as a store.

1. Log into the WarpStream console and create a virtual cluster at [console.warpstream.com/virtual_clusters/create][warpstream_console].
    - Select BYOC as the cluster type, not Serverless, and select `us-east-1` as the region.
    - Copy the virtual cluster’s ID and agent key.
2. Configure an S3 bucket and IAM role in AWS using the provided Terraform files.
    - `terraform init -upgrade && terraform apply`
    - Copy the S3 bucket URL and role ARN from the output.

### Part II. Deploy the agent

Release the WarpStream agent Helm chart and upload credentials to reach the S3 bucket.

1. Start a local session to manage your Kubernetes cluster and confirm you can reach it.
    - `aws eks update-kubeconfig --name $eks_cluster_name`
    - `kubectl get nodes # confirm cluster is reachable`
2. Release the Warpstream Helm chart into your Kubernetes cluster.
    - `helm repo add warpstream https://warpstreamlabs.github.io/charts`
    - `helm repo update`
    - Now release the chart into your cluster
    ```bash
        helm upgrade --install warpstream-agent warpstream/warpstream-agent \
        --set config.bucketURL="$bucket_url" \
        --set config.region="us-east-1" \
        --set config.apiKey="$agent_key" \
        --set config.virtualClusterID="$virtual_cluster_id"
    ```
3. Check the health of the Kubernetes pods running the WarpStream agent.
    - `kubectl get pods | grep warpstream`
    - `kubectl logs $warpstream_pod_name | less`
    - The pods should be failing with `AccessDenied` errors. This is expected: they’re still missing access to the S3 bucket.
        - The pods may be failing to start due to insufficient resources. If so, add more nodes to your Kubernetes cluster or increase your nodes’ instance size. See the WarpStream documentation on [instance type selection][].
4. Pass AWS credentials to the WarpStream pods as environment variables. Use the credentials obtained by assuming the AWS role whose ARN was printed by terraform apply.
    - `aws sts assume-role --role-arn $role_arn --role-session-name warpstream-byoc-demo`
    - `kubectl set env deployment/warpstream-agent AWS_ACCESS_KEY_ID=$access_key_id AWS_SECRET_ACCESS_KEY=$secret_access_key AWS_SESSION_TOKEN=$session_token`

[!WARNING]
For simplicity we’re using insecure environment variables to pass sensitive values. In production we would use a secrets manager. Or better yet, we would associate the IAM role to a Kubernetes service account. (See [Kubernetes docs][] and [AWS docs][].)

5. Give the WarpStream agent pods time to back off from the authorization errors and then check their logs again. Their status should be Running and their logs should no longer contain errors. If so, you have successfully deployed the WarpStream agent.

### Part III. Produce and consume messages

Observe the agent in action by producing and consuming messages.

[!NOTE]
These steps assume your Kubernetes nodes run on amd64 or arm64 Linux architectures. You can confirm by running `kubectl get nodes -o yaml | grep architecture`. If your nodes run a different architecture, you’ll need to provision new nodes running amd64 or arm64.

1. Provision a pod with the Kafka command line tools installed using the provided configuration file.
    - `kubectl apply -f warpstream-byoc-demo-pod.yaml`
2. In one Terminal window, open a shell in that pod and start an Apache Kafka consumer.
    - `kubectl exec -it warpstream-byoc-demo -- bash`
    - `kafka-console-consumer.sh --bootstrap-server warpstream-agent:9092 --topic test`
3. In another window, open another shell in that pod and start an Apache Kafka producer.
    - `kubectl exec -it warpstream-byoc-demo -- bash`
    - `kafka-console-producer.sh --bootstrap-server warpstream-agent:9092 --topic test`
4. Enter any values into the producer shell. You should see them appear in the consumer shell. This demonstrates the WarpStream agent streaming data in your own cloud. The servers running in WarpStream’s cloud only see your cluster’s metadata. The messages passed from the producer to the consumer stay entirely within your cloud.

[warpstream_console]: https://console.warpstream.com/virtual_clusters/create
[instance type selection]: https://docs.warpstream.com/warpstream/byoc/deploy#instance-selection
[Kubernetes docs]: https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/
[AWS docs]: https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html
