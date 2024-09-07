    ///////////////////////////////////////////////////////////////
                            Pendu (Guessing game)
    ///////////////////////////////////////////////////////////////


    How to play the game ? :

    1. Create a subscription at https://vrf.chain.link/ and copy its ID
    2. Deploy the SubscriptionConsumer contract using the previous subscription ID
    3. Add the SubscriptionConsumer contract address as consumer at https://vrf.chain.link/
    4. Deploy the Pendu contract with the SubscriptionConsumer contract address as parameter
    5. Execute the transferOwnership function of SubscriptionConsumer to give ownership to the newly deployed Pendu contract
    6. Accept the ownership using the approveOwnership function from Pendu
    7. Start playing : 
        - setPlayerName : will assign names to a player given his address
        - newGame : create a game with its attributes and start a random number generation
        - setRandomNumber: will retrieve the generated random number and bind it to the game
        - payToPlay: both players should pay the game's betting amount before playing
        - guessTheCorrectNUmber : the players try to guess the random number. The game return either 0 (smaller), 1 (equal) or 2(greater)

    
    Enjoy !!!