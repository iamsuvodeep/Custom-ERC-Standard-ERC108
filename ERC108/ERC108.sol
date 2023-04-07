// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


contract ERC108{

    string public currencyName;
    string public logo;
    uint256 public amount;
    struct currency{
        string name;
        string logo;
        address onwer;
    }

    struct Transaction{
        uint time;
        uint amount;
        address to;
        address from;
    }
    mapping(bytes32=>currency) public currencyNameById;
    mapping(string=>string) private currencyNames;
    mapping(address=>uint) private balances;
    mapping(address=>mapping(address=>mapping(uint=>bool))) public spenderApproval;
    mapping(bytes32=>mapping(address=>mapping(address=>bool))) public transactions;
    mapping(address=>mapping(address=>uint)) private transactionsAmount;
    mapping(address=>mapping(address=>uint256)) public spendingLimitAppoval;
    mapping(bytes32=>mapping(address=>uint)) public getBalancesByCurrencyId;
    mapping(string=>bytes32) private currencyHash;

    mapping(bytes32=>mapping(address=>mapping(address=>uint))) public getApprovalTransactionAmount;
    mapping(bytes32=>mapping(address=>mapping(uint=>address[]))) public groupSpenderLimit;

    mapping(bytes32=>Transaction) public transactionLogs;
    bytes32 [] public transactionHash;

    address public ___currencyOnwer;

    mapping(address=>address[]) public addtoaddTransaction;

    //event _viewApproval(bytes32 _txHash, address indexed  _onwer,address indexed _spender,uint _amount);
    event _transferMoney(bytes32 txHash, address from,address to, uint amount);
    
    function viewApprovalBalance(string memory _currencyLogo)public view returns(uint){
        bytes32 _currencyHash = keccak256(abi.encodePacked(_currencyLogo));
        address _onwer = currencyNameById[_currencyHash].onwer;
        //address _spender = msg.sender;
        uint _amount =  getApprovalTransactionAmount[_currencyHash][_onwer][msg.sender];
        //emit _viewApproval(_currencyHash,_onwer,_spender,_amount);
        return _amount;

    }

    function transferMoney(address to, uint _amount, string memory _currenyLogo) public returns(bytes32 txHash){
        require(to != msg.sender,"Self transfer is not allowed");
        ___currencyOnwer = msg.sender;
        bytes32 _currencyHash = getCurrencyHash(_currenyLogo);
        address _currecyOnwer = currencyNameById[_currencyHash].onwer;
        txHash = keccak256(abi.encodePacked(to,_amount,block.timestamp));
        transactionHash.push(txHash);
        //Checks if the sender is the onwer of currency
        if (getBalancesByCurrencyId[_currencyHash][msg.sender] >= _amount){
            getBalancesByCurrencyId[_currencyHash][msg.sender] -= _amount;
            getBalancesByCurrencyId[_currencyHash][to] += _amount;
            balances[to] += _amount;
            balances[msg.sender] -= _amount;
            transactions[_currencyHash][msg.sender][to] = true;
            transactionsAmount[msg.sender][to] += _amount;
            transactionLogs[txHash].time = block.timestamp;
            transactionLogs[txHash].amount = _amount;
            transactionLogs[txHash].to = to;
            transactionLogs[txHash].from = msg.sender;
            addtoaddTransaction[msg.sender].push(to);
            emit _transferMoney(txHash,msg.sender,to,_amount);
            return txHash;
            
        } 
        //Checks if this function is called by the Approve Spender
        if (spendingLimitAppoval[_currecyOnwer][msg.sender] >= _amount){
            spendingLimitAppoval[_currecyOnwer][msg.sender] -= _amount;
            getBalancesByCurrencyId[_currencyHash][to] += _amount;
            getBalancesByCurrencyId[_currencyHash][_currecyOnwer] -= _amount;
            transactions[_currencyHash][msg.sender][to] = true;
            transactionsAmount[msg.sender][to] = _amount;
            getApprovalTransactionAmount[_currencyHash][_currecyOnwer][msg.sender] -= _amount;
            transactionLogs[txHash].time = block.timestamp;
            transactionLogs[txHash].amount = _amount;
            transactionLogs[txHash].to = to;
            transactionLogs[txHash].from = msg.sender;
            addtoaddTransaction[msg.sender].push(to);
            emit _transferMoney(txHash,msg.sender,to,_amount);
            return txHash;

            
        }
        


        
    }

    event _allowSpender(bytes32 txHash,address from,address __spender,uint amount);


    function allowSpender(address _spender, uint256 _amount, string memory _currenyLogo) public{
        bytes32 _currencyHash = getCurrencyHash(_currenyLogo);
        require(balances[msg.sender] >= _amount,"Not Enough Balance");
        require(_spender != address(0),"Zero Address can't be a valid address");
        require(!spenderApproval[msg.sender][_spender][_amount],"Already Added to the list");
        spenderApproval[msg.sender][_spender][_amount] = true;
        //transactions[_currencyHash][msg.sender][_spender]  = true;
        spendingLimitAppoval[msg.sender][_spender] += _amount;
        getApprovalTransactionAmount[_currencyHash][msg.sender][_spender] += _amount;
        emit _allowSpender(_currencyHash,msg.sender, _spender,_amount);

    }

    


    function allowMultipleSpender(address [] memory addresses, uint _amount, string memory _currencyLogo) public{
        bytes32 _currencyHash = getCurrencyHash(_currencyLogo);
        require(getBalancesByCurrencyId[_currencyHash][msg.sender] >= _amount,"Not Enough Balance");
        groupSpenderLimit[_currencyHash][msg.sender][_amount] = addresses;
        for (uint i = 0; i<addresses.length; i++){
            spenderApproval[msg.sender][addresses[i]][_amount] = true;
            spendingLimitAppoval[msg.sender][addresses[i]] += _amount/addresses.length;
            getApprovalTransactionAmount[_currencyHash][msg.sender][addresses[i]] += _amount/addresses.length;
            emit _allowSpender(_currencyHash,msg.sender, addresses[i],_amount);

        }


    }

    


    
    event _mint(string  __currencyName,address _creator,uint _mintingAmount);

    function  mint(string memory _currencyName, string memory _logo, uint _amount) public{
        currencyName = _currencyName;
        logo = _logo;
        amount = _amount;
        bytes32 _currencyHash = keccak256(abi.encodePacked( _logo));
        currencyNameById[_currencyHash].name = _currencyName;
        currencyNameById[_currencyHash].logo = _logo;
        currencyNameById[_currencyHash].onwer = msg.sender;
        currencyNames[_logo] = _currencyName;
        balances[msg.sender] = _amount;
        currencyHash[_logo] = _currencyHash;
        getBalancesByCurrencyId[_currencyHash][msg.sender] = _amount;
        emit _mint(currencyName,msg.sender,_amount);
    }



    


    event getTransactMoney(address from,address to, uint amount, bytes32 txHassh);
    

     

    function getTransactionMoney(address from,string memory _currenyLogo)public view returns(uint256){
        bytes32 ch = currencyHash[_currenyLogo];
        require(transactions[ch][from][msg.sender] == true,"Transaction Not Happended");
        //uint _amount = transactionsAmount[from][msg.sender];
        return transactionsAmount[from][msg.sender];
        //emit getTransactMoney(from, msg.sender,_amount,ch);
        
    }



    

    function getCurrencyHash(string memory _currenyLogo) public view returns(bytes32){
        return currencyHash[_currenyLogo];
    }
    



    function totalSupply() public view returns(uint256){
        return amount;
    }


    function getCurrencyName(string calldata currencyLogo) public view returns(string memory){
        return currencyNames[currencyLogo];
    }

    function getBalanceByCurrency(string memory _currencyLogo) public view returns(uint){
        bytes32 ch = currencyHash[_currencyLogo];
        return getBalancesByCurrencyId[ch][msg.sender];
        
    }


}