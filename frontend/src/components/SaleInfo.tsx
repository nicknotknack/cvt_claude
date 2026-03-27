import { formatUnits } from 'viem'
import { useSaleInfo } from '../hooks/useSaleInfo'

const TOTAL_FOR_SALE = 1_000_000n

function formatCompact(value: number): string {
  if (value >= 1_000_000) {
    return (value / 1_000_000).toFixed(2).replace(/\.?0+$/, '') + 'M'
  }
  if (value >= 1_000) {
    const k = value / 1_000
    return (k >= 100 ? k.toFixed(0) : k >= 10 ? k.toFixed(1) : k.toFixed(2)).replace(/\.?0+$/, '') + 'K'
  }
  return value.toLocaleString()
}

export function SaleInfo() {
  const { tokensRemaining, totalTokensSold, saleActive, isLoading } =
    useSaleInfo()

  const sold = totalTokensSold ?? 0n
  const remaining = tokensRemaining ?? 0n
  const soldFormatted = formatUnits(sold, 18)
  const remainingFormatted = formatUnits(remaining, 18)
  const percentSold =
    sold > 0n
      ? Number((sold * 10000n) / (TOTAL_FOR_SALE * 10n ** 18n)) / 100
      : 0

  return (
    <div className="bg-white/5 backdrop-blur-xl border border-white/10 rounded-2xl p-6 mb-6">
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-xl font-semibold text-white">Token Sale</h2>
        {isLoading ? (
          <span className="text-gray-400 text-sm">Loading...</span>
        ) : (
          <span
            className={`px-3 py-1 rounded-full text-sm font-medium ${
              saleActive
                ? 'bg-green-500/20 text-green-400'
                : 'bg-red-500/20 text-red-400'
            }`}
          >
            {saleActive ? 'Active' : 'Inactive'}
          </span>
        )}
      </div>

      <div className="grid grid-cols-3 gap-4 mb-6">
        <div className="bg-white/5 rounded-xl p-4">
          <p className="text-gray-400 text-sm mb-1">Token Price</p>
          <p className="text-white font-semibold text-lg">0.0001 ETH</p>
          <p className="text-gray-500 text-xs">per 1 CVT</p>
        </div>
        <div className="bg-white/5 rounded-xl p-4">
          <p className="text-gray-400 text-sm mb-1">Tokens Remaining</p>
          <p className="text-white font-semibold text-lg">
            {isLoading ? '...' : formatCompact(Number(remainingFormatted))}
          </p>
          <p className="text-gray-500 text-xs">of 1M CVT</p>
        </div>
        <div className="bg-white/5 rounded-xl p-4">
          <p className="text-gray-400 text-sm mb-1">Tokens Sold</p>
          <p className="text-white font-semibold text-lg">
            {isLoading ? '...' : formatCompact(Number(soldFormatted))}
          </p>
          <p className="text-gray-500 text-xs">CVT</p>
        </div>
      </div>

      <div>
        <div className="flex justify-between text-sm mb-2">
          <span className="text-gray-400">Sale Progress</span>
          <span className="text-white font-medium">{percentSold.toFixed(2)}%</span>
        </div>
        <div className="w-full bg-white/10 rounded-full h-3 overflow-hidden">
          <div
            className="h-full rounded-full bg-gradient-to-r from-purple-500 to-cyan-400 transition-all duration-500"
            style={{ width: `${Math.min(percentSold, 100)}%` }}
          />
        </div>
      </div>
    </div>
  )
}
