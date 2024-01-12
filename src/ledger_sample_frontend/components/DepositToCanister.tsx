import React, { useState, useEffect } from "react"
import { useWallet, useTransfer, useCanister } from "@connect2ic/react"
import { ledger_sample_backend } from "../../declarations/ledger_sample_backend"; // Adjust the import path as necessary

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

    const [transfer, { error: useTransferError }] = useTransfer({
        to: canisterAccount,
        amount: Number(amount),
    });

    const onPurchase = async () => {
        if (amount > 0) {
            let transferResult;
            let retries = 0;
            const maxRetries = 5; // Set the maximum number of retries
    
            while (retries < maxRetries) {
                try {
                    transferResult = await transfer();
                    if (transferResult?.height) {
                        console.log("height: ", transferResult.height);
                        console.log("icpToE8s(amount): ", icpToE8s(amount));
                        const notifyResult = await authenticatedLedgerBackend.notifyDeposit(
                            transferResult.height, icpToE8s(amount)
                        );
                        console.log("Notify result: ", notifyResult);
                        break; // Exit the loop if height is received
                    }
                } catch (error) {
                    console.error("Error during transfer or notifyDeposit: ", error);
                }
                retries++;
                // Wait for the loading state to change before retrying
                while (useTransferError) {
                    await new Promise(resolve => setTimeout(resolve, 1000));
                }
            }
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
                    <button className="connect-button" onClick={onPurchase}>Deposit to Canister</button>
                </>
            ) : (
                <p className="deposit-to-canister-widget-disabled">Connect with a wallet to access this example</p>
            )}
        </div>
    );    
};

export { DepositToCanister }