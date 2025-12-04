/**
 * @hulud/ioc - Indicators of Compromise database
 *
 * Provides typed access to IOC data for Shai-Hulud 2.0 detection.
 */

import { createRequire } from 'module'

const require = createRequire(import.meta.url)

const hashes = require('./hashes.json')
const maliciousPackages = require('./malicious-packages.json')
const networkIOCs = require('./network.json')

/**
 * Get all known malicious packages
 * @returns {Array<{name: string, versions: string[], risk: string, source: string}>}
 */
export function getMaliciousPackages() {
  return maliciousPackages.packages || []
}

/**
 * Check if a package name is in the malicious list
 * @param {string} packageName
 * @returns {boolean}
 */
export function isMaliciousPackage(packageName) {
  const packages = getMaliciousPackages()
  return packages.some((pkg) => pkg.name === packageName)
}

/**
 * Get malicious package details
 * @param {string} packageName
 * @returns {object|null}
 */
export function getPackageDetails(packageName) {
  const packages = getMaliciousPackages()
  return packages.find((pkg) => pkg.name === packageName) || null
}

/**
 * Get all network IOCs (domains, IPs, URLs)
 * @returns {object}
 */
export function getNetworkIOCs() {
  return networkIOCs
}

/**
 * Get all known malicious file hashes
 * @returns {object}
 */
export function getHashes() {
  return hashes
}

/**
 * Check if a SHA256 hash is known malicious
 * @param {string} sha256
 * @returns {boolean}
 */
export function isMaliciousHash(sha256) {
  const hashData = getHashes()
  if (!hashData.files) return false

  return hashData.files.some((file) => file.hashes?.sha256 === sha256)
}

// Export raw data for direct access
export { hashes, maliciousPackages, networkIOCs }

// Default export
export default {
  getMaliciousPackages,
  isMaliciousPackage,
  getPackageDetails,
  getNetworkIOCs,
  getHashes,
  isMaliciousHash,
  maliciousPackages,
  networkIOCs,
  hashes,
}
