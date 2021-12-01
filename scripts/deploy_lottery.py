from brownie import accounts, config, Lottery, network
from brownie.network import account
from scripts.helpful_scripts import fund_with_link, get_account, get_contract
import time

def deploy_lottery():
    account = get_account()
    lottery = Lottery.deploy(
        get_contract("eth_usd_price_feed").address,
        get_contract("vrf_coordinator").address,
        get_contract("link_token").address,
        config["networks"][network.show_active()]["fee"],
        config["networks"][network.show_active()]["keyhash"],
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify",False),
    ) 
    print("Deployed Lottery !")
    return lottery
    
def start_lottery():
    account = get_account()
    lottery = Lottery[-1]
    starting_tx = lottery.startLottery({"from": account})
    starting_tx.wait(1)
    print("The lottery has started !!")

def enter_lottery():
    account = get_account()
    lottery = Lottery[-1]
    value = lottery.getEntranceFee() + 100000000
    tx = lottery.enter({"from": account, "value": value})
    tx.wait(1)
    print("You have successfully entered the lottery 🙌 ")

def end_lottery():
    account = get_account()
    lottery = Lottery[-1]
    # fund contract 
    # pay link token and end lottery
    tx = fund_with_link(lottery.address)
    tx.wait(1)
    endind_tx = lottery.endLottery({"from": account})
    endind_tx.wait(1)
    time.sleep(60)
    print(f"{lottery.recentWinner()} is the new Winner ✨" )
    print("Ending Lottery ✔ ")


def main():
    deploy_lottery()
    start_lottery()
    enter_lottery()
    end_lottery()