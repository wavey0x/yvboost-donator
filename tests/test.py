import pytest
import brownie
from brownie import config, Contract, accounts, interface, chain
from brownie import network


def test_operation(donator, sms, ychad, yvboost, rando, chain):
    tx = yvboost.transfer(donator, yvboost.balanceOf(sms) / 2, {"from":sms})
    assert yvboost.balanceOf(donator) > 0
    starting_total_supply = yvboost.totalSupply()
    yveCrv = Contract(yvboost.token())
    starting_bal_donator = yvboost.balanceOf(donator)
    starting_bal_yveCrv = yveCrv.balanceOf(yvboost)

    tx = donator.donate({"from":rando})
    print(tx.events["Donated"])
    with brownie.reverts():
        donator.donate({"from":rando}) # Should fail due to too soon
    chain.sleep(donator.donateInterval())
    chain.snapshot()
    donator.donate({"from":rando})
    chain.revert()
    assert tx.events["Donated"]["amountBurned"] == starting_total_supply - yvboost.totalSupply()
    assert tx.events["Donated"]["amountBurned"] == starting_bal_donator - yvboost.balanceOf(donator)
    assert yveCrv.balanceOf(yvboost) >= starting_bal_yveCrv

def test_front_run(donator, sms, ychad, yvboost, rando, chain, yvecrv):
    # Setup front runner to deposit
    yvecrv_whale = accounts.at("0x1b9524b0F0b9F2e16b5F9e4baD331e01c2267981", force=True) # largest yveCRV holder who is not sushipool or strategy
    front_runner = accounts[1]
    yvecrv.transfer(front_runner, yvecrv.balanceOf(yvecrv_whale), {"from": yvecrv_whale})
    yvecrv.approve(yvboost, 2**256-1, {"from": front_runner})
    front_runner_beginning_balance = yvecrv.balanceOf(front_runner)
    
    # Move money to donation contract
    tx = yvboost.transfer(donator, yvboost.balanceOf(sms) / 2, {"from":sms})
    assert yvboost.balanceOf(donator) > 0

    # Deposit and donate
    yvboost.deposit({"from": front_runner})
    before_pps = yvboost.pricePerShare()
    tx = donator.donate({"from":rando})
    print("pps gain",(yvboost.pricePerShare() - before_pps) / 1e18)
    print(tx.events["Donated"])
    with brownie.reverts():
        donator.donate({"from":rando}) # Should fail due to too soon
    chain.sleep(donator.donateInterval() + 1)
    chain.mine(2)
    chain.snapshot()
    chain.mine(2)
    donator.donate({"from":rando})
    chain.revert()
    yvboost.withdraw({"from": front_runner})
    bal_diff = yvecrv.balanceOf(front_runner) - front_runner_beginning_balance
    print("yveCRV gain for front runner", bal_diff / 1e18)

def test_change_gov(donator, sms, ychad, yvboost, rando, chain):
    with brownie.reverts():
        donator.setGovernance(rando, {"from":rando})
    donator.setGovernance(ychad, {"from":sms})
    assert donator.governance() == sms
    donator.acceptGovernance({"from":ychad})

def test_sweep(donator, sms, ychad, yvboost, dai, rando, chain):
    before_balance = dai.balanceOf(sms)
    with brownie.reverts():
        donator.sweep(yvboost, {"from":rando})
    donator.sweep(yvboost, {"from":sms})
    donator.sweep(dai, {"from":sms})
    assert dai.balanceOf(sms) > before_balance

def test_set_donate_interval(donator, sms, ychad, yvboost, rando, chain):
    with brownie.reverts():
        donator.setDonateInterval(100, {"from":rando})
    donator.setDonateInterval(100, {"from":sms})
    assert donator.donateInterval() == 100

def test_set_max_burn_amount(donator, sms, ychad, yvboost, rando, chain):
    with brownie.reverts():
        donator.setMaxBurnAmount(1_000, {"from":rando})
    donator.setMaxBurnAmount(100, {"from":sms})
    assert donator.maxBurnAmount() == 100

def test_disable_public_donations(donator, sms, ychad, yvboost, rando, chain):
    tx = yvboost.transfer(donator, yvboost.balanceOf(sms), {"from":sms})
    with brownie.reverts():
        donator.togglePublicDonations({"from":rando})
    donator.togglePublicDonations({"from":sms})
    chain.sleep(donator.donateInterval() + 1)
    chain.mine(1)
    with brownie.reverts():
        donator.donate({"from":rando})
    donator.donate({"from":sms})