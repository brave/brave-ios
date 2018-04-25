/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */

const I = (x) => x

/**
 * Same as filterPredicate but will log if there is a LOG_OUTPUT env variable
 */
const filterPredicateWithPossibleLogging = (rule, filterPredicate = I) => {
  const result = filterPredicate(rule)
  if (process.env['LOG_OUTPUT'] && !result) {
    console.log('Filtering out rule: ', rule)
  }
  return result
}

/**
 * Mapping rule which reformats rules
 */
const mapRule = (rule) => rule

/**
 * Given a list of inputs returns a filtered list of rules that should be used.
 *
 * @param input {string} - ABP filter syntax to filter
 * @return A better filter list
 */
const sanitizeABPInput = (input, filterPredicate = I) =>
  input.split('\n')
    .filter((rule) =>
      filterPredicateWithPossibleLogging(rule, filterPredicate))
    .map(mapRule)
    .join('\n')

module.exports = {
  sanitizeABPInput
}
