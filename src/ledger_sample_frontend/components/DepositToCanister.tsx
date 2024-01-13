import React, { useState, useEffect } from "react"
import { useWallet, useTransfer, useCanister } from "@connect2ic/react"
import { ledger_sample_backend } from "../../declarations/ledger_sample_backend"; // Adjust the import path as necessary
import { Result_1 } from "../../declarations/ledger_sample_backend/ledger_sample_backend.did";

const DepositToCanister = () => {

    const [wallet] = useWallet()
    const [amount, setAmount] = useState(0.0001); // Default amount or could be empty string ''
    const [canisterAccount, setCanisterAccount] = useState('');
    const [authenticatedLedgerBackend, { error, loading: ledgerBackendLoading }] = useCanister('ledger_sample_backend');

    const icpToE8s = (icpAmount: number) => {
        return BigInt(Math.floor(icpAmount * 1e8));
    };

    useEffect(() => {
        const fetchCanisterAccount = async () => {
            const account = await ledger_sample_backend.getCanisterAccountId();
            setCanisterAccount(account);
        };
        fetchCanisterAccount();
    }, []);

    const [transfer, { loading, error: useTransferError }] = useTransfer({
        to: canisterAccount,
        amount: Number(amount),
    });


    const maxRetries = 5;
    let retryCount = 0;
    let delay = 2000;
    let success = false;

    const pollForBlockHeight = async () => {
        while (retryCount < maxRetries && !success) {
            try {
                const transferResult = await transfer();
                if (transferResult?.height) {
                    console.log("height: ", transferResult.height);
                    console.log("icpToE8s(amount): ", icpToE8s(amount));
                    const notifyResult = await authenticatedLedgerBackend.notifyDeposit(
                        transferResult.height, icpToE8s(amount)
                    ) as Result_1;
                    if ('ok' in notifyResult) {
                        console.log("Success on notify: ", notifyResult);
                        success = true;
                        break; // Exit the loop if height is received
                    } else {
                        console.log("Non ok Notify result: ", notifyResult);
                    }                    
                }
            } catch (error) {
                console.error("Error during transfer attempt:", error);
                retryCount++;
                console.log(`Retrying transfer... (${retryCount}/${maxRetries})`);
                // Wait for a delay before retrying
                await new Promise(resolve => setTimeout(resolve, delay));
                delay *= 2; // Optionally implement exponential backoff
            }
            if (useTransferError) {
                console.error('Transfer error:', useTransferError);
                // Handle the transfer error, e.g., display an error message to the user
            }
        }
        if (!success) {
            throw new Error("Failed to obtain a valid block height after maximum retries.");
        }
    };

    // Usage of pollForBlockHeight
    const onDeposit = async () => {
        try {
            console.log("called onDeposit, waiting for pollForBlockHeight");
            const blockHeight = await pollForBlockHeight();
            // Proceed with the block height
        } catch (error) {
            // Handle the case where a valid block height was not obtained
            console.error(error);
        }
    };


    return (
        <div className="deposit-to-canister-widget">
            {wallet ? (
                <>
                    <p>Deposit ICP to Canister: {canisterAccount} </p>
                    <input
                        type="number"
                        value={amount}
                        onChange={(e) => setAmount(Number(e.target.value))}
                        className="amount-input"
                        placeholder="Amount ICP"
                        step="0.0001"
                    />
                    <button className="connect-button" onClick={onDeposit} disabled={loading}>Deposit to Canister</button>
                </>
            ) : (
                <p className="deposit-to-canister-widget-disabled">Connect with a wallet to access this example</p>
            )}
        </div>
    );
};

export { DepositToCanister }