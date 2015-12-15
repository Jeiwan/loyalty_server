# Loyalty Server

Provides API to work with loyalty programs (cumulative discounts) during sellings and web-interface to track sales, loyalty cards, and purchases.

# Description

This Rails Engine was developed for a Russian drug store network counting 1000+ stores. In each sotre they had a computer with Rails application which they used to sale goods, track goods in stock, print receipts, order goods from suppliers etc. They wanted this Rails application to have ability to work with loyalty programs, that provide cumulative discounts for each sale.

Another requirement were regular reports sent to my client's email. The reports had to be in Excel format and contain statistics of recent registered cards, taken gifts, activated certificates.

# Tasks

My task was to implement an API server that has all the business logic related to the loyalty programs; implement web-interface to track statistic of registered loyalty cards, purchases, loyalty certificates etc.; design user experience in main Rails application and integrate loyalty programs into it.

# Scenarios

These are the main scenarios:

1. If buyer agrees to participate in the loyalty program, then a loyalty card is given to them.

2. Loyalty card is scanned before selling. During selling the purchase is registered on Loyalty Server (a new record in `purchases` table is created).

3. Buyer recevies some loyalty points on his card, depending on the sum of the purache.

4. After collecting certain amount of loyalty points, buyer can choose a gift. After taking a gift buyer's card is blocked and cannot be used anymore.

5. Buyer can take a loyalty certificate as a gift. The certificate gives one time discount of 2000 roubles.


# Internal Structure

The engine implements both REST API and usual web-interface. The API implements business logic to work with loyalty programs, and drug store Rails application sends requests to this API to register loyalty card, check available gifts for the card, register/return/rollback purchases etc. The web-interface gives statistics on the usage of loyalty cards, certificates and registered purchases/returns.

The core functionality is implemented in Purchase model in `register` method. It registeres purchases (creates a new record in `purchases` table), that can be of 3 types: purchase with loyalty card (when loyalty program was activated on drug store and loyalty card was scanned), with card and certificate (when loyalty certificate is activated and in the receipt), with certificate only (when buyer applied certificate and its fixed discount). This was the most difficult place in the engine, it took me some time to find this pattern and concisely describe it in the code.
