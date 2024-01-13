import React, { useState, useEffect } from 'react';
import { useCanister } from "@connect2ic/react";
import { Principal } from '@dfinity/principal';

interface DepositRecord {
    principal: Principal;
    amount: bigint; // Replace 'number' with the correct type for the amount
}

// Define the type for a single deposit array
type RawDepositArray = [string, number | string];

// Define the type for the raw deposits
type RawDeposits = RawDepositArray[];


const CanisterDepositsWidget: React.FC = () => {
    const [balances, setBalances] = useState<DepositRecord[]>([]);
    const [isFetching, setIsFetching] = useState(false);
    const [ledgerBackend] = useCanister('ledger_sample_backend');

    const fetchBalances = async () => {
        if (ledgerBackend && !isFetching) {
            setIsFetching(true);
            setBalances([]); // Clear out current balances
            try {
                const rawDeposits = await ledgerBackend.getAllDeposits() as RawDeposits;
                console.log('Deposits:', rawDeposits); // Log the raw deposits data

                const deposits = rawDeposits.map(depositArray => ({
                    principal: Principal.from(depositArray[0]),
                    amount: BigInt(depositArray[1]),
                })) as DepositRecord[];

                console.log('Processed Balances:', deposits); // Log the processed data
                setBalances(deposits);
            } catch (error) {
                console.error('Error fetching balances:', error);
            } finally {
                setIsFetching(false);
            }
        }
    };

    useEffect(() => {
        fetchBalances();
    }, [ledgerBackend]);

    return (
        <div className="balances-widget">
            <h3>Canister Deposits by Principal, in e8s</h3>
            <button onClick={fetchBalances} disabled={isFetching}>
                {isFetching ? 'Fetching Balances...' : 'Refresh Balances'}
            </button>
            <ul>
                {balances.map((record, index) => (
                    <li key={index}>
                        Principal: {record.principal ? record.principal.toText() : 'N/A'}, 
                        Amount in e8s: {record.amount ? record.amount.toString() : 'N/A'}
                    </li>
                ))}
            </ul>
        </div>
    );
};

export default CanisterDepositsWidget;