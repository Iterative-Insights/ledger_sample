import React, { useState } from 'react';

const DepositWidget = ({ onDeposit }) => {
  const [amount, setAmount] = useState('');

  const handleDeposit = async () => {
    if (amount) {
      await onDeposit(amount);
      setAmount('');
    }
  };

  return (
    <div>
      <h2>Deposit ICP</h2>
      <input
        type="number"
        value={amount}
        onChange={(e) => setAmount(e.target.value)}
        placeholder="Enter amount to deposit"
      />
      <button onClick={handleDeposit}>Deposit</button>
    </div>
  );
};

export default DepositWidget;