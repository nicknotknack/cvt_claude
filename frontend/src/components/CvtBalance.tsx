import { useAccount, useReadContract } from 'wagmi'
import { formatUnits } from 'viem'
import { TOKEN_ADDRESS, CryptoVisionTokenABI } from '../config/contracts'

function formatCvt(raw: bigint): string {
  const value = Number(formatUnits(raw, 18))
  if (value >= 1_000_000) {
    return (value / 1_000_000).toFixed(4).replace(/\.?0+$/, '') + 'M'
  }
  if (value >= 1_000) {
    return value.toLocaleString(undefined, { maximumFractionDigits: 2 })
  }
  return value.toLocaleString(undefined, { maximumFractionDigits: 4 })
}

export function CvtBalance() {
  const { address, isConnected } = useAccount()

  const { data: balance, isLoading } = useReadContract({
    address: TOKEN_ADDRESS,
    abi: CryptoVisionTokenABI,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
    query: {
      enabled: isConnected && !!address,
      refetchInterval: 10_000,
    },
  })

  if (!isConnected) return null

  return (
    <div className="bg-white/5 backdrop-blur-xl border border-white/10 rounded-2xl p-6 mb-6">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-gray-400 text-sm mb-1">Your CVT Balance</p>
          <p className="text-2xl font-bold bg-gradient-to-r from-purple-400 to-cyan-400 bg-clip-text text-transparent">
            {isLoading
              ? '...'
              : balance !== undefined
                ? formatCvt(balance as bigint)
                : '0'}{' '}
            <span className="text-lg font-semibold text-white/70">CVT</span>
          </p>
        </div>
        <div className="w-12 h-12 rounded-full bg-gradient-to-br from-purple-500/20 to-cyan-500/20 border border-white/10 flex items-center justify-center">
          <span className="text-xl font-bold bg-gradient-to-r from-purple-400 to-cyan-400 bg-clip-text text-transparent">
            C
          </span>
        </div>
      </div>
    </div>
  )
}
