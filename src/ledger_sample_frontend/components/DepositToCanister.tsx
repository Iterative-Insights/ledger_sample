import React, { useState, useEffect } from "react"
import { useWallet, useTransfer, useCanister } from "@connect2ic/react"
import { ledger_sample_backend } from "../../declarations/ledger_sample_backend"; // Adjust the import path as necessary
import { Result_1 } from "../../declarations/ledger_sample_backend/ledger_sample_backend.did";

interface DepositToCanisterProps {
    afterDeposit: (status: 'success' | 'error', details: any) => void;
    afterNotify: (status: 'success' | 'error', details: any) => void;
}


const DepositToCanister: React.FC<DepositToCanisterProps> = ({ 
    afterDeposit, afterNotify }) => {

    const [wallet] = useWallet()
    const [amount, setAmount] = useState(0.0001); // Default amount or could be empty string ''
    const [canisterAccount, setCanisterAccount] = useState('');
    const [authenticatedLedgerSampleBackend, { error, loading: ledgerBackendLoading }] = useCanister('ledger_sample_backend');
    const [blockHeight, setBlockHeight] = useState<number | null>(null);
    const [isNotifyEnabled, setIsNotifyEnabled] = useState(false);

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
        amount: Number(amount)
    });

    useEffect(() => {
        if (useTransferError) {
            console.log('Transfer Error:', useTransferError);
        }
    }, [useTransferError]); 

    const depositActions = async () => {
        if (amount) {
            const result = await transfer();
            if (result && 'ok' in result) {
                const height = result.ok;
                setBlockHeight(height); // Set the block height from the transfer
                setIsNotifyEnabled(true);
                afterDeposit('success', height);
            } else if (result) {
                const errorMessage = result.err
                afterDeposit('error', errorMessage);
                console.error('Transfer failed:', errorMessage);
            } else {
                afterDeposit('error', useTransferError?.message);
                console.error('transfer returned undefined.');
            }
        }
    };

    const notifyActions = async () => {
        if (blockHeight !== null && amount) {
            const e8sAmount = icpToE8s(amount);
            const notifyResult = await authenticatedLedgerSampleBackend.notifyDeposit(
                blockHeight, e8sAmount
            ) as Result_1;
            if (notifyResult && 'ok' in notifyResult) {
                console.log("Success on notify: ", notifyResult);
                await afterNotify('success', { blockHeight, e8sAmount });
            } else if (notifyResult) {
                const errorMessage = notifyResult.err; // Define errorMessage here
                await afterNotify('error', errorMessage);
                console.log("Non ok Notify result: ", notifyResult);
            } else {
                console.error('notifyDeposit returned undefined.');
            }
            setIsNotifyEnabled(false); // Disable the button after notifying
            setAmount(0);//reset amount after notify
            setBlockHeight(null);
        }
    };

    return (
        <div className="deposit-to-canister-widget">
            {wallet ? (
                <>
                    <h2>Deposit ICP to Canister Acct: {canisterAccount}</h2>
                    {loading && <div>Loading...</div>}
                    {useTransferError && <div>Error: {useTransferError.message}</div>}
                    <input
                        type="number"
                        value={amount}
                        onChange={(e) => setAmount(Number(e.target.value))}
                        placeholder="Enter amount to deposit"
                    />
                    <button onClick={depositActions} disabled={loading}>Deposit</button>
                    {blockHeight !== null && <p>Block Height: {blockHeight}</p>}
                    <button onClick={notifyActions} disabled={!isNotifyEnabled || loading}>Notify</button>
                </>
            ) : (
                <p className="deposit-to-canister-widget-disabled">Connect with a wallet to access this example</p>
            )}
        </div>
    );
};

export { DepositToCanister }