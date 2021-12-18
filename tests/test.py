import pytest
from brownie import config, Contract, accounts, interface
from brownie import network


def test_operation(donator, sms, ychad, yvboost, rando):
    yvboost = interface.IVault(yvboost)
    yveCrv = Contract(yvboost.token())
    starting_bal_donator = yvboost.balanceOf(donator)
    starting_bal_yvboost = yveCrv.balanceOf(yvboost)
    tx = donator.donate({"from":rando})
    print(tx.events["Donated"])
    with brownie.reverts():
        donator.donate({"from":rando})
    assert tx["Donated"]["amountBurned"] == starting_bal_donator - yvboost.balanceOf(donator)
    assert tx["Donated"]["amountDonated"] == starting_bal_yvboost - yveCrv.balanceOf(yvboost)

def test_change_gov(donator, sms, ychad, yvboost, rando):
    with brownie.reverts():
        donator.setGovernance(rando, {"from":rando})
    donator.setGovernance(ychad, {"from":sms})
    assert donator.governance() == sms
    donator.acceptGonvernance({"from":ychad})

def test_sweep(donator, sms, ychad, yvboost, dai, rando):
    before_balance = dai.balanceOf(sms)
    with brownie.reverts():
        donator.sweep(yvboost, {"from":rando})
    donator.sweep(yvboost, {"from":sms})
    donator.sweep(dai, {"from":sms})
    assert dai.balanceOf(sms) > before_balance

def test_set_donate_interval(donator, sms, ychad, yvboost, rando):
    with brownie.reverts():
        donator.setDonateInterval(100, {"from":rando})
    donator.setDonateInterval(100, {"from":sms})