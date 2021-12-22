import pytest, web3
from brownie import config, Contract, accounts, interface
from brownie import network

@pytest.fixture(autouse=True)
def isolation(fn_isolation):
    pass

@pytest.fixture
def sms(accounts, web3):
    yield accounts.at(web3.ens.resolve("brain.ychad.eth"), force=True)

@pytest.fixture
def ychad(accounts, web3):
    yield accounts.at(web3.ens.resolve("ychad.eth"), force=True)

@pytest.fixture
def yvboost():
    yield interface.IVault("0x9d409a0A012CFbA9B15F6D4B36Ac57A46966Ab9a")

@pytest.fixture
def yvecrv(yvboost):
    yield Contract(yvboost.token())

@pytest.fixture
def rando(accounts):
    yield accounts[0]

@pytest.fixture
def rando(accounts):
    yield accounts[0]

@pytest.fixture
def donator(Donator, rando, sms, yvboost):
    donator = rando.deploy(Donator)
    yield donator

@pytest.fixture
def dai(accounts, donator):
    dai = Contract("0x6B175474E89094C44Da98b954EedeAC495271d0F")
    holder = accounts.at("0x6B175474E89094C44Da98b954EedeAC495271d0F", force=True)
    dai.transfer(donator, 100e18, {"from": holder})
    yield dai