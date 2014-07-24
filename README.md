# Bitcoin Payment Channels

*aka: Bitcoin Micropayments / Microtransactions*

A quickstart CoffeeScript node server, designed to serve compiled, minified, and source-mapped CoffeeScript modules to the browser, templated with Handlebars. 

## Quickstart

Install [nodejs](http://nodejs.org/download/).

First we need to setup the server-side (the content provider):

```bash
$ git clone https://github.com/jesstelford/mcp.git && cd mcp
$ npm install # Install all the npm dependancies
$ ./bin/serverd --init
$ SERVERD=password ./bin/serverd --init
```

*(replace `password` with the password you'd like to use to access the local
database)*

Next, we need to setup the client-side (the content consumer / requester of
payment channels).

In a new terminal window run the following:

```bash
$ git clone https://github.com/jesstelford/payment-channels.git && cd payment-channels
$ npm install # Install all the npm dependancies
$ make        # Build the project, and fire up a minimal server
```

In a third window, we will now trigger the creation of a new payment channel:

```bash
curl http://localhost:3000?pubkey=PUBKEY&privkey=PRIVKEY
```

*(replace `PUBKEY` and `PRIVKEY` with the pubkey/privkey of `K1` that you wish
to use. See below for more details)*

## How it works

This implementation follows the algorithm laid out in the [*"Rapidly-adjusted (micro)payments to a pre-determined party"](https://en.bitcoin.it/wiki/Contracts#Example_7:_Rapidly-adjusted_.28micro.29payments_to_a_pre-determined_party) Bitcoin wiki page:

> We define the client to be the party sending value, and the server to be the party receiving it. This is written from the clients perspective **(aka: this repo)**
> 
> 1. Create a public key `K1`. Request a public key from the server `K2`.
> 2. Create and sign but do not broadcast a transaction `T1` that sets up a payment of (for example) 10 BTC to an output requiring both the server's public key and one of your own to be used. A good way to do this is use `OP_CHECKMULTISIG`. The value to be used is chosen as an efficiency tradeoff.
> 3. Create a refund transaction `T2` that is connected to the output of `T1` which sends all the money back to yourself. It has a time lock set for some time in the future, for instance a few hours. Don't sign it, and provide the unsigned transaction to the server. By convention, the output script is `2 K1 K2 2 CHECKMULTISIG`
> 4. The server signs `T2` using its public key `K2` and returns the signature to the client. Note that it has not seen `T1` at this point, just the hash (which is in the unsigned `T2`).
> 5. The client verifies the servers signature is correct and aborts if not.
> 6. The client signs `T1` and passes the signature to the server, which now broadcasts the transaction (either party can do this if they both have connectivity). This locks in the money.
> 7. The client then creates a new transaction, `T3`, which connects to `T1` like the refund transaction does and has two outputs. One goes to `K1` and the other goes to `K2`. It starts out with all value allocated to the first output (`K1`), ie, it does the same thing as the refund transaction but is not time locked. The client signs `T3` and provides the transaction and signature to the server.
> 8. The server verifies the output to itself is of the expected size and verifies the client's provided signature is correct.
> 9. When the client wishes to pay the server, it adjusts its copy of `T3` to allocate more value to the server's output and less to its own. It then re-signs the new `T3` and sends the **transaction** to the server. The server verifies the signature and continues.
> 
> This continues until the session ends, or the 1-day period is getting close to expiry. The srever then signs and broadcasts the last transaction it saw, allocating the final amount to itself. The refund transaction is needed to handle the case where the server disappears or halts at any point, leaving the allocated value in limbo. If this happens then once the time lock has expired the client can broadcast the refund transaction and get back all the money.

*Note:* I have marked the differences to the original algorithm in **bold**

## Project Structure

See
[http://github.com/jesstelford/coffee-boilerplate#project-structure](Coffee-Boilerplate)
for information on how this repo is laid out.

## Powered By

 * [Coffee-boilerplate](https://github.com/jesstelford/coffee-boilerplate)
 * [Bitcore](https://github.com/bitpay/bitcore)
 * [node.js](http://nodejs.org)

## Donations

<img src="http://dogecoin.com/imgs/dogecoin-300.png" width=100 height=100 align=right />
Like what I've created? *So do I!* I develop this project in my spare time, free for the community.

If you'd like to say thanks, buy me a beer by **tipping with Dogecoin**: *D7cw4vVBwZRwrZkEw8L7rqt8cX24QCbZxV*
