#!/bin/bash

echo "Starting Helm uninstalls for Retail Store Sample App..."
echo

# Step 05 - UI Service
echo "Uninstalling UI Service..."
helm uninstall ui-vpw
#sleep 10
echo

# Step 04 - Orders Service
echo "Uninstalling Orders Service..."
helm uninstall orders-vpw
sleep 10
echo

# Step 03 - Checkout Service
echo "Uninstalling Checkout Service..."
helm uninstall checkout-vpw
sleep 10
echo

# Step 02 - Cart Service
echo "Uninstalling Cart Service..."
helm uninstall cart-vpw
sleep 10
echo

# Step 01 - Catalog Service
echo "Uninstalling Catalog Service..."
helm uninstall catalog-vpw
sleep 10
echo

echo
echo "All Helm uninstalls completed!"
