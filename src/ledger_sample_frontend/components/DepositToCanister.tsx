import React, { useState, useEffect } from "react"
import { useWallet, useTransfer, useCanister, useConnect } from "@connect2ic/react"
import { ledger_sample_backend } from "../../declarations/ledger_sample_backend"; // Adjust the import path as necessary
import { Result_1 } from "../../declarations/ledger_sample_backend/ledger_sample_backend.did";

interface DepositToCanisterProps {
    afterDeposit: (status: 'success' | 'error', details: { height?: number, amount?: number, message?: string }) => void;
    afterNotify: (status: 'success' | 'error', details: { height?: bigint, e8sAmount?: bigint, message?: string }) => void;
}

const DepositToCanister: React.FC<DepositToCanisterProps> = ({
    afterDeposit, afterNotify }) => {

    const [wallet] = useWallet()
    const [amount, setAmount] = useState(0.0001); // Default amount or could be empty string ''
    const [canisterAccount, setCanisterAccount] = useState('');
    const [authenticatedLedgerSampleBackend, { error, loading: ledgerBackendLoading }] = useCanister('ledger_sample_backend');
    const [blockHeight, setBlockHeight] = useState<number | null>(null);
    const [isNotifyEnabled, setIsNotifyEnabled] = useState(false);
    const [isWalletConnected, setIsWalletConnected] = useState(false);
    const connector = useConnect();
    const [isNotifying, setIsNotifying] = useState(false);    

    const icpToE8s = (icpAmount: number) => {
        return BigInt(Math.floor(icpAmount * 1e8));
    };

    useEffect(() => {
        // Assuming connector is an object that has isConnected as a boolean property
        setIsWalletConnected(connector.isConnected);

        // If the connector object provides an event listener for when the connection status changes
        const handleConnectionChange = () => {
            setIsWalletConnected(connector.isConnected);
        };
        
    }, [connector]); // Re-run this effect if the connector object changes


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

    useEffect(() => {
        // This effect runs when the blockHeight state changes.
        // If blockHeight is not null, it means a deposit has been made and we have a new height.
        // We can then proceed to notify.
        const autoNotify = async () => {
          if (blockHeight !== null && !isNotifying) {
            await notifyActions();
          }
        };
      
        autoNotify();
      }, [blockHeight]); // Only re-run the effect if blockHeight changes.

    const depositActions = async () => {
        if (amount) {
            const result = await transfer();
            console.log("transfer result from depositActions: ", result)
            if (result && 'height' in result && typeof result.height === 'number') {
                const height = result.height;
                setBlockHeight(height); // Set the block height from the transfer
                setIsNotifyEnabled(true);
                afterDeposit('success', { height: height, amount: amount });
            } else {
                // The error could be in result.err or in useTransferError.
                const errorMessage =  useTransferError?.kind || "Unknown error";
                afterDeposit('error', { message: errorMessage, amount: amount });
                console.error('Transfer failed:', errorMessage , '. Amount: ', amount);
            }
        }
    };

    const notifyActions = async () => {
        if (blockHeight !== null && amount) {
            try {
                setIsNotifying(true);
                const e8sAmount = icpToE8s(amount);
                const notifyResult = await authenticatedLedgerSampleBackend.notifyDeposit(
                    blockHeight, e8sAmount
                ) as Result_1;
                if (notifyResult && 'ok' in notifyResult) {
                    console.log("Success on notify: ", notifyResult);
                    await afterNotify('success', { height: notifyResult.ok, e8sAmount });
                } else if (notifyResult) {
                    const errorMessage = { message: notifyResult.err }; // Define errorMessage here
                    await afterNotify('error', errorMessage);
                    console.log("Non ok Notify result: ", errorMessage);
                } else {
                    console.error('notifyDeposit returned undefined.');
                }                
                // setAmount(0);//reset amount after notify
                setBlockHeight(null);
            } catch (error) {
                console.error('Notification failed', error);
            } finally {
                setIsNotifying(false);
                setIsNotifyEnabled(false);
            }
        }
    };

    return (
        <div className="deposit-to-canister-widget">
            <div>
                {isWalletConnected ? (
                    <p>Wallet is connected.</p>
                ) : (
                    <p>Wallet is not connected.</p>
                )}
            </div>
            {wallet ? (
                <>
                    <h2>Deposit ICP to Canister Acct: {canisterAccount}</h2>
                    {loading && <div>Loading...</div>}
                    {useTransferError && <div>Error: {useTransferError.kind}</div>}
                    <input
                        type="number"
                        value={amount}
                        onChange={(e) => setAmount(Number(e.target.value))}
                        placeholder="Enter amount to deposit"
                    />
                    <button onClick={depositActions} disabled={isNotifyEnabled || loading}>Deposit</button>
                    <button onClick={notifyActions} disabled={!isNotifyEnabled || isNotifying || loading}> 
                        {isNotifying ? 'Notifying...' : 'Notify'}</button>
                    {blockHeight !== null && <p>Block Height: {blockHeight}</p>}
                </>
            ) : (
                <p className="deposit-to-canister-widget-disabled">Connect with a wallet to access this example</p>
            )}
        </div>
    );
};

export { DepositToCanister }