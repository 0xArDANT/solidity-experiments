//SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;
import "@openzeppelin/contracts/utils/Strings.sol";

// Jeu du pendu
// Intervalle de jeu : customisable
// Les joeurs mettent des tokens en jeu
// 2 Joueurs doivent deviner le nombre aléatoire choisi par le programme
// Nombre d'essais : illimité

contract Pendu {
    uint256 public gameCount = 0;

    struct Game {
        uint256 amountToBet;
        address launcher;
        address challenger;
        uint256 lowerLimit;
        uint256 upperLimit;
        uint256 randomNumber;
        Status status;
        Winner winner;
    }

    mapping(address => string) players;
    mapping(uint256 => Game) public games;
    mapping(address => bool) isPlayer;
    mapping(uint256 => bool) isGame;
    mapping(address => mapping(uint256 => bool)) playerHasPaid;
    mapping(address => uint256) balance;

    enum Status {
        ONGOING,
        FINISHED
    }

    enum Winner {
        LAUNCHER,
        CHALLENGER
    }

    modifier gameExist(uint256 _gameId) {
        require(isGame[_gameId], "The game doesn't exist !");
        _;
    }

    modifier onlyLauncher(uint256 _gameId) {
        require(
            games[_gameId].launcher == msg.sender,
            "You're not the launcher of this game"
        );
        _;
    }

    modifier onlyPlayer(uint256 _gameId) {
        require(
            msg.sender == games[_gameId].launcher ||
                msg.sender == games[_gameId].challenger,
            "You're not a player of this game"
        );
        _;
    }

    function newGame(
        address _player2Addr,
        uint256 _amountToBet,
        uint256 _lowerLimit,
        uint256 _upperLimit
    ) public {
        require(msg.sender != _player2Addr, "You can't play against yourself");
        require(_amountToBet >= 0, "The betting amount should be positive");
        require(
            _lowerLimit < _upperLimit,
            "The lower limit should be less than the upper"
        );
        gameCount++;
        Game storage game = games[gameCount];
        isGame[gameCount] = true;
        game.amountToBet = _amountToBet;
        game.launcher = msg.sender;
        game.challenger = _player2Addr;
        game.lowerLimit = _lowerLimit;
        game.upperLimit = _upperLimit;
        game.status = Status.ONGOING;
        game.randomNumber = generateRandomNumber(
            gameCount,
            _lowerLimit,
            _upperLimit
        );
    }

    //The users should pay before playing
    function payToPlay(uint256 _gameId)
        public
        payable
        gameExist(_gameId)
        onlyPlayer(_gameId)
    {
        uint256 amountToBetInGwei = games[_gameId].amountToBet * (10**18);
        require(
            msg.value == amountToBetInGwei,
            string.concat(
                "Make sure to send the right amount of ether : ",
                Strings.toString(games[_gameId].amountToBet),
                " ether"
            )
        );
        playerHasPaid[msg.sender][_gameId] = true;
    }

    function setPlayerName(string memory _playerName) public {
        players[msg.sender] = _playerName;
    }

    function generateRandomNumber(
        uint256 _gameId,
        uint256 _lowerLimit,
        uint256 _upperLimit
    ) internal view gameExist(_gameId) returns (uint256) {
        uint256 randomNumber = (uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender, _gameId))
        ) % (_upperLimit - _lowerLimit + 1)) + _lowerLimit;

        return randomNumber;
    }

    function updateGameIntervals(
        uint256 _gameId,
        uint256 _newLowerLimit,
        uint256 _newUpperLimit
    ) public gameExist(_gameId) onlyLauncher(_gameId) {
        games[_gameId].lowerLimit = _newLowerLimit;
        games[_gameId].upperLimit = _newUpperLimit;
        games[_gameId].randomNumber = generateRandomNumber(
            _gameId,
            _newLowerLimit,
            _newUpperLimit
        );
    }

    function updateAmountToBet(uint256 _gameId, uint256 _newAmount)
        public
        gameExist(_gameId)
        onlyLauncher(_gameId)
    {
        require(_newAmount > 0, "The amount should be greater than 0");
        games[_gameId].amountToBet = _newAmount;
    }

    function guessTheCorrectNumber(uint256 _gameId, uint256 _guessedNumber)
        public
        payable
        gameExist(_gameId)
        onlyPlayer(_gameId)
        returns (string memory)
    {
        require(
            playerHasPaid[msg.sender][_gameId] == true,
            "You should send your betting amount before playing"
        );
        require(games[_gameId].status == Status.ONGOING, "The game has ended");
        require(
            _guessedNumber >= games[_gameId].lowerLimit &&
                _guessedNumber <= games[_gameId].upperLimit,
            "The number is out of limits"
        );

        if (_guessedNumber > games[_gameId].randomNumber)
            return "Your number is too great";
        else if (_guessedNumber < games[_gameId].randomNumber)
            return "Your number is too small";
        else {
            if (msg.sender == games[_gameId].launcher)
                games[_gameId].winner = Winner.LAUNCHER;
            else if (msg.sender == games[_gameId].challenger)
                games[_gameId].winner = Winner.CHALLENGER;

            //Pay the winner and close the game
            payable(msg.sender).transfer(
                games[_gameId].amountToBet * (10**18) * 2
            );
            games[_gameId].status = Status.FINISHED;

            return string.concat("The winner is ", players[msg.sender]);
        }
    }

    function anotherGame(uint256 _gameId)
        public
        gameExist(_gameId)
        onlyLauncher(_gameId)
    {
        newGame(
            games[_gameId].challenger,
            games[_gameId].amountToBet,
            games[_gameId].lowerLimit,
            games[_gameId].upperLimit
        );
    }

    // In case the player send tokens by accident

    receive() external payable {
        balance[msg.sender] += msg.value;
    }

    function withdrawBalance() public payable {
        require(balance[msg.sender] > 0, "You don't have funds");
        payable(msg.sender).transfer(balance[msg.sender]);
    }
}

// Next steps
// Permettre le jeu à 2 en créant une partie qui prend en compte l'addresse des joueurs - OK
// Permettre aux joueurs de choisir l'intervalle de jeu - OK
// permettre aux joeurs de recommencer la partie OK
// Permettre aux joeurs de mettre des tokens en jeu qui seront sauvegardés par le smart contract et transférés au gagnant OK
// Ajout des contrôles d'accès - OK
// Faire en sorte que les joeurs doivent jouer l'un après l'autre
// Rendre le nombre réellement aléatoire grâce aux oracles
// Améliorer ce que la fonction guess retourne.
// Gestion d'erreurs
// Ajout des évènements pour le frontend
// Permettre aux joueurs de laisser leurs gains dans le contrat et ne payer pour jouer que si leur balance du contrat est plus petit que le montant à jouer.
// Sécurité du contrat intelligent
// Permettre le jeu en plusieurs manches
