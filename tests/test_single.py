import os
import pytest

from starkware.starknet.testing.starknet import Starknet

CONTRACT_FILE = os.path.join(
    os.path.dirname(__file__), "../contracts/single.cairo")

@pytest.mark.asyncio
async def test_view_cell():

    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()

    # Deploy the contract.
    contract = await starknet.deploy(
        source=CONTRACT_FILE)

    await contract.make_move(
        game_id=3, row=2, col=1, val=1).invoke()

    
    assert await contract.view_cell(
        game_id=3, row=2, col=1).call() == (0)