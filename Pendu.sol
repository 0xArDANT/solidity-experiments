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

    enum Status {
        ONGOING,
        FINISHED
    }

    enum Winner {
        LAUNCHER,
        CHALLENGER
    }

    modifier onlyLauncher(uint256 _gameId) {
        require(
            games[_gameId].launcher == msg.sender,
            "You're not the launcher of this game"
        );
        _;
    }

    function intitializeGame(
        address _player2Addr,
        uint256 _lowerLimit,
        uint256 _upperLimit
    ) public {
        gameCount++;
        Game storage newGame = games[gameCount];
        newGame.launcher = msg.sender;
        newGame.challenger = _player2Addr;
        newGame.lowerLimit = _lowerLimit;
        newGame.upperLimit = _upperLimit;
        newGame.status = Status.ONGOING;

        newGame.randomNumber =
            (uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, gameCount)
                )
            ) % _upperLimit) +
            1;
        if (newGame.randomNumber < _lowerLimit)
            newGame.randomNumber += _upperLimit - _lowerLimit;
    }

    function setPlayerName(string memory _playerName) public {
        players[msg.sender] = _playerName;
    }

    function guessTheCorrectNumber(uint256 _gameId, uint256 _guessedNumber)
        public
        returns (string memory)
    {
        require(
            _guessedNumber > games[_gameId].lowerLimit &&
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
}

// Next steps
// Permettre le jeu à 2 en créant une partie qui prend en compte l'addresse des joueurs - OK
// Permettre aux joueurs de choisir l'intervalle de jeu - OK
// permettre aux joeurs de recommencer automatiquement la partie, en cas de victoire.
// Rendre le nombre réellement aléatoire grâce aux oracles
// Améliorer ce que la fonction guess retourne.
// Gestion d'erreurs
// Ajout du contrôle et des mesures de sécurité
// Permettre aux joeurs de mettre des tokens en jeu qui seront sauvegardés par le smart contract et transférés au gagnant.
// Permettre le jeu en plusieurs manches
