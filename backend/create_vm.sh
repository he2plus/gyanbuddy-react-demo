#!/bin/bash

# Quick script to create GCP VM for Gyaan Buddy Backend
# Project ID: caramel-goal-473111-t3

set -e

PROJECT_ID="caramel-goal-473111-t3"
VM_NAME="gyaan-buddy-backend"
ZONE="us-central1-a"
MACHINE_TYPE="e2-medium"

echo "🚀 Creating VM for Gyaan Buddy Backend..."
echo "Project: $PROJECT_ID"
echo "VM Name: $VM_NAME"
echo "Zone: $ZONE"
echo ""

# Set the project
gcloud config set project $PROJECT_ID

# Create the VM
echo "📦 Creating VM instance..."
gcloud compute instances create $VM_NAME \
    --project=$PROJECT_ID \
    --zone=$ZONE \
    --machine-type=$MACHINE_TYPE \
    --image-family=ubuntu-2204-lts \
    --image-project=ubuntu-os-cloud \
    --boot-disk-size=30GB \
    --boot-disk-type=pd-standard \
    --tags=http-server,https-server \
    --metadata=startup-script='#!/bin/bash
apt-get update
apt-get install -y python3 python3-pip python3-venv git'

echo ""
echo "✅ VM created successfully!"
echo ""

# Get the external IP
echo "📡 Getting external IP address..."
EXTERNAL_IP=$(gcloud compute instances describe $VM_NAME \
    --project=$PROJECT_ID \
    --zone=$ZONE \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo ""
echo "🌐 External IP: $EXTERNAL_IP"
echo ""
echo "📝 Next steps:"
echo "1. Connect to VM:"
echo "   gcloud compute ssh $VM_NAME --project=$PROJECT_ID --zone=$ZONE"
echo ""
echo "2. Copy setup script to VM:"
echo "   gcloud compute scp setup_gcp_vm.sh $VM_NAME:~/ --project=$PROJECT_ID --zone=$ZONE"
echo ""
echo "3. On VM, run:"
echo "   chmod +x setup_gcp_vm.sh"
echo "   sudo ./setup_gcp_vm.sh"
echo ""
echo "4. Deploy your application:"
echo "   Option A - Clone from Git:"
echo "   cd /opt"
echo "   sudo git clone git@github.com:theshushant/gyaan_buddy_backend.git gyaan_buddy_backend"
echo "   cd gyaan_buddy_backend"
echo "   sudo chown -R \$USER:\$USER ."
echo ""
echo "   Option B - Copy from local machine:"
echo "   gcloud compute scp --recurse . $VM_NAME:/opt/gyaan_buddy_backend/ --project=$PROJECT_ID --zone=$ZONE"
echo ""
echo "5. On VM, configure and deploy:"
echo "   cd /opt/gyaan_buddy_backend"
echo "   cp env.production.example .env"
echo "   nano .env  # Edit with your production values"
echo "   chmod +x deploy.sh"
echo "   ./deploy.sh"
echo ""
echo "6. Don't forget to update ALLOWED_HOSTS in .env with: $EXTERNAL_IP"

