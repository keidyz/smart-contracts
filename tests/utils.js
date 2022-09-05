function sendEther(web3, from, to, amount) {
    return web3.eth.sendTransaction({
        from,
        to,
        value: web3.utils.toWei(amount.toString(), "ether")
    });
}

function pow(x, y) {
    return Math.pow(x, y);
}

async function getUserBalance(tokenInstance, account) {
    return(await tokenInstance.balanceOf(account)).toNumber()
}

function eventLogsArrayToObject(eventLogsArray) {
    return eventLogsArray.reduce((acc, {event}) => {
        acc[event] = acc[event] ? acc[event] + 1 : 1;
        return acc
    }, {})
}

module.exports = {
    sendEther,
    pow,
    getUserBalance,
    eventLogsArrayToObject
}