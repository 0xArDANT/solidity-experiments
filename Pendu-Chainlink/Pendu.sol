//SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

import "@openzeppelin/contracts/utils/Strings.sol";
import {SubscriptionConsumer} from "SubscriptionConsumer.sol";

/**
 * @title Pendu (Guessing Game)
 * @author [0xArDANT]
 * @notice A simple hangman-style guessing game implemented as a smart contract with Chainlink oracle for number generation.
 * @dev This contract allows two players to engage in a guessing game with customizable betting amounts and intervals.
 */
contract Pendu {
    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint8 constant MAX_PLAYERS = 2;

    /*//////////////////////////////////////////////////////////////
                                IMMUTABLE VARIABLES
    //////////////////////////////////////////////////////////////*/
    SubscriptionConsumer private immutable subscriptionConsumer;

    /*//////////////////////////////////////////////////////////////
                                STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint256 public gameCount = 0;

    mapping(address playerAddress => string playerName) playerName;
    mapping(uint256 gameId => Game) public games;
    mapping(uint256 gameId => bool) isGame;
    mapping(uint256 gameId => address currentPlayer) currentGamePlayer;
    mapping(uint256 gameId => uint256 chainlinkRequestId) gameRequest;

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct Game {
        uint256 amountToBet;
        address launcher;
        address challenger;
        uint96 lowerLimit;
        uint96 upperLimit;
        uint256 randomNumber;
        uint8 status;
        uint8 winner;
        bool[7] playerHasPaid;
    }

    /*//////////////////////////////////////////////////////////////
                                ENUMS
    //////////////////////////////////////////////////////////////*/

    enum NumberStatus {
        SMALLER,
        EQUAL,
        GREATER
    }

    enum GameStatus {
        INITIALIZED,
        ONGOING,
        FINISHED
    }

    enum Winner {
        NONE,
        LAUNCHER,
        CHALLENGER
    }

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event NewGameEvent(uint256 gameId);
    event GameAmountUpdatedEvent(uint256 gameId, uint256 newAmount);
    event PlayerPaidEvent(address playerAddress, uint256 gameId);
    event GameStatusUpdatedEvent(uint256 gameId, uint8 newStatus);
    event NewGuessedNumberEvent(address, uint256, NumberStatus result);

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    //Used to make sure a game exists
    modifier gameExist(uint256 _gameId) {
        require(isGame[_gameId], "The game doesn't exist !");
        _;
    }

    // Verify if the game is in the "right Phase"
    modifier isGameCurrentStatus(uint256 _gameId, uint8 _status) {
        require(games[_gameId].status == _status, "Invalid game phase");
        _;
    }

    // Verify it's the game's launcher
    modifier onlyLauncher(uint256 _gameId) {
        require(games[_gameId].launcher == msg.sender, "You're not the launcher of this game");
        _;
    }

    // Verify it's one of the two game's players
    modifier onlyPlayer(uint256 _gameId) {
        require(
            msg.sender == games[_gameId].launcher || msg.sender == games[_gameId].challenger,
            "You're not a player of this game"
        );
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _subscriptionConsumerAddress) {
        subscriptionConsumer = SubscriptionConsumer(_subscriptionConsumerAddress);
    }

    /*//////////////////////////////////////////////////////////////
                                GAME LOGIC
    //////////////////////////////////////////////////////////////*/

    // The users must start by setting their name
    function setPlayerName(string memory _playerName) public {
        playerName[msg.sender] = _playerName;
    }

    // Create and intitialize a new game
    function newGame(address _player2Addr, uint256 _amountToBet, uint96 _lowerLimit, uint96 _upperLimit) public {
        require(msg.sender != _player2Addr, "You can't play against yourself");
        require(_amountToBet >= 0, "The betting amount should be positive");
        require(_lowerLimit < _upperLimit, "The lower limit should be less than the upper");
        gameCount++;
        Game storage game = games[gameCount];
        isGame[gameCount] = true;
        game.amountToBet = _amountToBet;
        game.launcher = msg.sender;
        game.challenger = _player2Addr;
        game.lowerLimit = _lowerLimit;
        game.upperLimit = _upperLimit;
        game.status = uint8(GameStatus.INITIALIZED);

        // Request a random number generation from Chainlink
        uint256 requestId = subscriptionConsumer.requestRandomWords(false);
        gameRequest[gameCount] = requestId;

        emit NewGameEvent(gameCount);
    }

    // Get the random number generated by Chainlink and make sure it fits the limits
    function setRandomNumber(uint256 _gameId) public gameExist(_gameId) onlyLauncher(_gameId) returns (uint256) {
        // The modulo of the generated number divided by (upper - lower + 1) will produce a number less than or equal their difference
        // Then adding this number to lowerLimit ensure the final will be at least the lower and at most the upper number.
        uint256 requestId = gameRequest[_gameId];
        (bool futfilled, uint256[] memory randomWords) = subscriptionConsumer.getRequestStatus(requestId);
        require(futfilled, "The random number hasn't been generated yet");

        uint256 randomNumber =
            (randomWords[0] % (games[_gameId].upperLimit - games[_gameId].lowerLimit + 1)) + games[_gameId].lowerLimit;
        games[_gameId].randomNumber = randomNumber;
        return randomNumber;
    }

    //The users should pay before playing
    function payToPlay(uint256 _gameId)
        public
        payable
        gameExist(_gameId)
        onlyPlayer(_gameId)
        isGameCurrentStatus(_gameId, uint8(GameStatus.INITIALIZED))
    {
        uint8 playerIndex = msg.sender == games[_gameId].launcher ? 0 : 1;
        require(!games[_gameId].playerHasPaid[playerIndex], "You already paid");
        require(
            msg.value == games[_gameId].amountToBet,
            string.concat(
                "Make sure to send the right amount of ether : ", Strings.toString(games[_gameId].amountToBet), " ether"
            )
        );
        games[_gameId].playerHasPaid[playerIndex] = true;

        if (bothPlayersPaid(_gameId)) {
            games[_gameId].status = uint8(GameStatus.ONGOING);
            emit GameStatusUpdatedEvent(_gameId, games[_gameId].status);
        }

        emit PlayerPaidEvent(msg.sender, _gameId);
    }

    // The players try to guess the correct number randomly generated.
    function guessTheCorrectNumber(uint256 _gameId, uint256 _guessedNumber)
        public
        payable
        gameExist(_gameId)
        onlyPlayer(_gameId)
        isGameCurrentStatus(_gameId, uint8(GameStatus.ONGOING))
        returns (NumberStatus)
    {
        require(
            currentGamePlayer[_gameId] == 0x0000000000000000000000000000000000000000
                || currentGamePlayer[_gameId] == msg.sender,
            "It's not your turn to play"
        );
        require(
            _guessedNumber >= games[_gameId].lowerLimit && _guessedNumber <= games[_gameId].upperLimit,
            "The number is out of limits"
        );

        // Setting the next user to play
        if (msg.sender == games[_gameId].launcher) {
            currentGamePlayer[_gameId] = games[_gameId].challenger;
        } else {
            currentGamePlayer[_gameId] = games[_gameId].launcher;
        }

        // Verifying if the number provided by the player is the correct one
        if (_guessedNumber > games[_gameId].randomNumber) {
            emit NewGuessedNumberEvent(msg.sender, _gameId, NumberStatus.GREATER);
            return NumberStatus.GREATER;
        } else if (_guessedNumber < games[_gameId].randomNumber) {
            emit NewGuessedNumberEvent(msg.sender, _gameId, NumberStatus.SMALLER);
            return NumberStatus.SMALLER;
        } else {
            emit NewGuessedNumberEvent(msg.sender, _gameId, NumberStatus.EQUAL);

            if (msg.sender == games[_gameId].launcher) {
                games[_gameId].winner = uint8(Winner.LAUNCHER);
            } else if (msg.sender == games[_gameId].challenger) {
                games[_gameId].winner = uint8(Winner.CHALLENGER);
            }

            //Pay the winner and close the game
            payable(msg.sender).transfer(games[_gameId].amountToBet * 2);
            games[_gameId].status = uint8(GameStatus.FINISHED);

            emit GameStatusUpdatedEvent(_gameId, games[_gameId].status);

            return NumberStatus.EQUAL;
        }
    }

    // Launch another base with the current game information, in case the players want to play again.
    function anotherGame(uint256 _gameId)
        public
        gameExist(_gameId)
        onlyLauncher(_gameId)
        isGameCurrentStatus(_gameId, uint8(GameStatus.FINISHED))
    {
        newGame(
            games[_gameId].challenger, games[_gameId].amountToBet, games[_gameId].lowerLimit, games[_gameId].upperLimit
        );
    }

    // The launcher of the game can update the amount to bet as long as no one played yet
    function updateAmountToBet(uint256 _gameId, uint256 _newAmount)
        public
        gameExist(_gameId)
        onlyLauncher(_gameId)
        isGameCurrentStatus(_gameId, uint8(GameStatus.INITIALIZED))
    {
        require(_newAmount > 0, "The amount should be greater than 0");
        games[_gameId].amountToBet = _newAmount;

        emit GameAmountUpdatedEvent(_gameId, _newAmount);
    }

    // Verify if both players of a game paid the betting amount
    function bothPlayersPaid(uint256 _gameId) internal view returns (bool) {
        return games[_gameId].playerHasPaid[0] && games[_gameId].playerHasPaid[1];
    }

    /*//////////////////////////////////////////////////////////////
                                FALLBACK
    //////////////////////////////////////////////////////////////*/

    // In case the player send tokens by accident to the contract
    receive() external payable {
        balance[msg.sender] += msg.value;
    }

    function withdrawBalance() public payable {
        require(balance[msg.sender] > 0, "You don't have funds");
        payable(msg.sender).transfer(balance[msg.sender]);
    }

    mapping(address => uint256) balance;
}

// TO-DO List

// Allow 2-player mode by creating a game that takes into account the addresses of the players - OK
// Allow players to choose the game interval - OK
// Allow players to restart the game - OK
// Allow players to put tokens in play that will be saved by the smart contract and transferred to the winner - OK
// Add access controls - OK
// Ensure that players must take turns playing - OK
// Add events for the frontend - OK
// Improve what the guess function returns - OK
// Add an interface for the contract - OK
// Make the number truly random using oracles: OK
// pack the struct game - OK
// Correct code formatting - OK
// Limit access to the subscrpition consumer contract
// Error handling
// Allow players to leave their winnings in the contract and only pay to play if their contract balance is smaller than the amount to play.
// Smart contract security
// Allow multi-round gameplay
