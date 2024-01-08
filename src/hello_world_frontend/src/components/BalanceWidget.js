import React, { useEffect, useState } from 'react';

const BalanceWidget = ({ getBalance }) => {
  const [balance, setBalance] = useState('Loading...');

  useEffect(() => {
    const fetchBalance = async () => {
      const balance = await getBalance();
      setBalance(balance);
    };

    fetchBalance();
  }, [getBalance]);

  return (
    <div>
      <h2>Your Current Balance</h2>
      <p>{balance} ICP</p>
    </div>
  );
};

export default BalanceWidget;