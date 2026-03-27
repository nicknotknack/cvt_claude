import { useState, useCallback, useEffect } from 'react'
import { useAccount, useBalance } from 'wagmi'
import { formatEther, parseEther } from 'viem'
import { useBuyTokens } from '../hooks/useBuyTokens'
import { TOKEN_ADDRESS } from '../config/contracts'
import { TransactionStatus } from './TransactionStatus'

export function BuyForm() {
  const [ethAmount, setEthAmount] = useState('')
  const [cvtAmount, setCvtAmount] = useState('')

  const { address, isConnected } = useAccount()
  const { data: balance, refetch: refetchBalance } = useBalance({
    address,
    query: { refetchInterval: 5_000 },
  })
  const { buyTokens, hash, isConfirming, isConfirmed, isPending, error } =
    useBuyTokens()

  useEffect(() => {
    if (isConfirmed) refetchBalance()
  }, [isConfirmed, refetchBalance])

  const handleEthChange = useCallback((value: string) => {
    setEthAmount(value)
    if (value && !isNaN(Number(value)) && Number(value) > 0) {
      setCvtAmount(String(Number(value) * 10000))
    } else {
      setCvtAmount('')
    }
  }, [])

  const handleCvtChange = useCallback((value: string) => {
    setCvtAmount(value)
    if (value && !isNaN(Number(value)) && Number(value) > 0) {
      setEthAmount(String(Number(value) / 10000))
    } else {
      setEthAmount('')
    }
  }, [])

  const handleBuy = () => {
    if (!ethAmount || Number(ethAmount) <= 0) return
    buyTokens(ethAmount)
  }

  const addTokenToWallet = async () => {
    try {
      await window.ethereum?.request({
        method: 'wallet_watchAsset',
        params: {
          type: 'ERC20',
          options: {
            address: TOKEN_ADDRESS,
            symbol: 'CVT',
            decimals: 18,
          },
        },
      })
    } catch {
      // User rejected or error
    }
  }

  const hasInsufficientBalance =
    balance && ethAmount
      ? parseEther(ethAmount || '0') > balance.value
      : false

  const buyDisabled =
    !isConnected ||
    !ethAmount ||
    Number(ethAmount) <= 0 ||
    hasInsufficientBalance ||
    isPending ||
    isConfirming

  return (
    <div className="bg-white/5 backdrop-blur-xl border border-white/10 rounded-2xl p-6 mb-6">
      <h2 className="text-xl font-semibold text-white mb-6">Buy CVT Tokens</h2>

      {isConnected && balance && (
        <div className="text-right text-sm text-gray-400 mb-4">
          Balance: {Number(formatEther(balance.value)).toFixed(4)} ETH
        </div>
      )}

      <div className="space-y-4 mb-6">
        <div>
          <label className="block text-sm text-gray-400 mb-2">You Pay</label>
          <div className="relative">
            <input
              type="number"
              min="0"
              step="0.001"
              placeholder="0.0"
              value={ethAmount}
              onChange={(e) => handleEthChange(e.target.value)}
              className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white text-lg placeholder-gray-600 focus:outline-none focus:border-purple-500 transition-colors [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
            />
            <span className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 font-medium">
              ETH
            </span>
          </div>
        </div>

        <div className="flex justify-center">
          <div className="w-8 h-8 rounded-full bg-white/10 flex items-center justify-center text-gray-400">
            ↓
          </div>
        </div>

        <div>
          <label className="block text-sm text-gray-400 mb-2">You Receive</label>
          <div className="relative">
            <input
              type="number"
              min="0"
              step="1"
              placeholder="0"
              value={cvtAmount}
              onChange={(e) => handleCvtChange(e.target.value)}
              className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white text-lg placeholder-gray-600 focus:outline-none focus:border-purple-500 transition-colors [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
            />
            <span className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 font-medium">
              CVT
            </span>
          </div>
        </div>
      </div>

      {hasInsufficientBalance && (
        <p className="text-red-400 text-sm mb-4">Insufficient ETH balance</p>
      )}

      <button
        onClick={handleBuy}
        disabled={buyDisabled}
        className="w-full py-3 px-6 rounded-xl font-semibold text-white bg-gradient-to-r from-purple-600 to-cyan-500 hover:brightness-110 transition-all disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:brightness-100"
      >
        {!isConnected
          ? 'Connect Wallet'
          : isPending
            ? 'Confirm in Wallet...'
            : isConfirming
              ? 'Processing...'
              : 'Buy CVT'}
      </button>

      <TransactionStatus
        hash={hash}
        isConfirming={isConfirming}
        isConfirmed={isConfirmed}
        error={error}
      />

      {isConfirmed && (
        <button
          onClick={addTokenToWallet}
          className="w-full mt-3 py-2 px-4 rounded-xl text-sm font-medium text-purple-400 border border-purple-500/30 hover:bg-purple-500/10 transition-colors"
        >
          Add CVT to Wallet
        </button>
      )}
    </div>
  )
}
