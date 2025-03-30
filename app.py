import streamlit as st
from web3 import Web3

infura_url = "https://sepolia.infura.io/v3/YOUR_INFURA_PROJECT_ID"
w3 = Web3(Web3.HTTPProvider(infura_url))

contract_address = "0xYourDeployedContractAddress"
abi = [
    {"inputs": [], "name": "donate", "outputs": [], "stateMutability": "payable", "type": "function"},
    {"inputs": [{"internalType": "uint256", "name": "_proposalId", "type": "uint256"}], "name": "vote", "outputs": [], "stateMutability": "nonpayable", "type": "function"},
    {"inputs": [{"internalType": "uint256", "name": "_proposalId", "type": "uint256"}], "name": "withdrawFunds", "outputs": [], "stateMutability": "nonpayable", "type": "function"},
    {"inputs": [], "name": "getBalance", "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}], "stateMutability": "view", "type": "function"}
]

contract = w3.eth.contract(address=contract_address, abi=abi)

st.title("Web3 Crowdfunding DAO")

user_address = st.text_input("Your Ethereum Address:")

amount_eth = st.number_input("Enter Donation Amount (ETH):", min_value=0.01, step=0.01)

if st.button("Donate"):
    if user_address and amount_eth:
        amount_wei = w3.to_wei(amount_eth, "ether")
        txn = contract.functions.donate().build_transaction({
            "from": user_address,
            "value": amount_wei,
            "gas": 200000,
            "gasPrice": w3.to_wei("10", "gwei"),
            "nonce": w3.eth.get_transaction_count(user_address)
        })
        st.success(f"Transaction Created! Send it using MetaMask.")
    else:
        st.error("Enter a valid Ethereum address and amount.")

proposal_id = st.number_input("Enter Proposal ID to Vote:", min_value=0, step=1)

if st.button("Vote"):
    txn = contract.functions.vote(proposal_id).build_transaction({
        "from": user_address,
        "gas": 200000,
        "gasPrice": w3.to_wei("10", "gwei"),
        "nonce": w3.eth.get_transaction_count(user_address)
    })
    st.success(f"Vote Transaction Created! Submit it on MetaMask.")

if st.button("Check Balance"):
    balance_wei = contract.functions.getBalance().call()
    balance_eth = w3.from_wei(balance_wei, "ether")
    st.info(f"Total Donations: {balance_eth} ETH")
