//SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

// Jeu du pendu
// Intervalle de jeu : customisable
// 2 Joueurs doivent deviner le nombre aléatoire choisi par le programme
// Nombre d'essais : illimité

contract Pendu {
    uint256 public gameCount = 0;

    struct Game {
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
        uint256 _lowerLimit,
        uint256 _upperLimit
    ) public {
        require(msg.sender != _player2Addr, "You can't play against yourself");
        require(
            _lowerLimit < _upperLimit,
            "The lower limit should be less than the upper"
        );
        gameCount++;
        isGame[gameCount] = true;
        Game storage game = games[gameCount];
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

    function setPlayerName(string memory _playerName) public {
        players[msg.sender] = _playerName;
    }

    function generateRandomNumber(
        uint256 _gameId,
        uint256 _lowerLimit,
        uint256 _upperLimit
    ) gameExist(_gameId) internal view returns (uint256) {
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

    function guessTheCorrectNumber(uint256 _gameId, uint256 _guessedNumber)
        public
        gameExist(_gameId)
        onlyPlayer(_gameId)
        returns (string memory)
    {
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
            games[_gameId].status = Status.FINISHED;

            if (msg.sender == games[_gameId].launcher)
                games[_gameId].winner = Winner.LAUNCHER;
            else if (msg.sender == games[_gameId].challenger)
                games[_gameId].winner = Winner.CHALLENGER;

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
            games[_gameId].lowerLimit,
            games[_gameId].upperLimit
        );
    }
}

// Next steps
// Permettre le jeu à 2 en créant une partie qui prend en compte l'addresse des joueurs - OK
// Permettre aux joueurs de choisir l'intervalle de jeu - OK
// permettre aux joeurs de recommencer la partie OK
// Rendre le nombre réellement aléatoire grâce aux oracles
// Améliorer ce que la fonction guess retourne.
// Gestion d'erreurs
// Ajout des contrôles d'accès - OK
// Sécurité du contrat intelligent
// Permettre aux joeurs de mettre des tokens en jeu qui seront sauvegardés par le smart contract et transférés au gagnant.
// Permettre le jeu en plusieurs manches
