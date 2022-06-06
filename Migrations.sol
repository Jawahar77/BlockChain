  // SPDX-License-Identifier: MIT
  // OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

  pragma solidity 0.8.13;

  import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
  import "@openzeppelin/contracts/utils/Context.sol";
  import "@openzeppelin/contracts/utils/math/SafeMath.sol";
  import "@openzeppelin/contracts/access/Ownable.sol";
  import "@openzeppelin/contracts/utils/Address.sol";



  interface IUniswapV2Router01 {
      function factory() external pure returns (address);
      function WETH() external pure returns (address);
  }

  interface IUniswapV2Router02 is IUniswapV2Router01 {
    
      function addLiquidityETH(
          address token,
          uint amountTokenDesired,
          uint amountTokenMin,
          uint amountETHMin,
          address to,
          uint deadline
      ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

      function swapExactTokensForETHSupportingFeeOnTransferTokens(
          uint amountIn,
          uint amountOutMin,
          address[] calldata path,
          address to,
          uint deadline
      ) external;
  }



  contract HolyBible is Context, IERC20, Ownable {
      using SafeMath for uint256;
      using Address for address;

      mapping (address => uint256) private _rOwned;
      mapping (address => uint256) private _tOwned;
      mapping (address => mapping (address => uint256)) private _allowances;

      mapping (address => bool) private _isExcluded;
      address[] private _excluded;
    
      uint256 private constant MAX = ~uint256(0);
      uint256 private constant _tTotal = 10 * 10**12 * 10**18;
      uint256 private _rTotal = (MAX - (MAX % _tTotal));
      uint256 private _tFeeTotal;

      bool private community;
      bool private marketing;
        bool private buyBNB;
        bool private refle;

      address public UNISWAPV2ROUTER;
      IUniswapV2Router02 public uniswapV2Router;

      string private _name = 'Holy Bible';
      string private _symbol = 'FAITH';
      uint8 private _decimals = 18;
      uint256 private totaltax=5;
      uint256 private prevtoatalTax;

      constructor () {
          _rOwned[_msgSender()] = _rTotal;
          
          UNISWAPV2ROUTER = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
          IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(UNISWAPV2ROUTER);
          uniswapV2Router = _uniswapV2Router;
          emit Transfer(address(0), _msgSender(), _tTotal);
      }

      function name() public view returns (string memory) {
          return _name;
      }

      function symbol() public view returns (string memory) {
          return _symbol;
      }

      function decimals() public view returns (uint8) {
          return _decimals;
      }

      function totalSupply() public pure override returns (uint256) {
          return _tTotal;
      }

      function balanceOf(address account) public view override returns (uint256) {
          if (_isExcluded[account]) return _tOwned[account];
          return tokenFromReflection(_rOwned[account]);
      }

      function transfer(address recipient, uint256 amount) public override returns (bool) {
        address from=_msgSender();
      if(from==UNISWAPV2ROUTER || recipient==UNISWAPV2ROUTER){
          _transfer(_msgSender(), recipient, amount);
      }else{
          prevtoatalTax=totaltax;
          totaltax=0;
            _transfer(_msgSender(), recipient, amount);
            totaltax=prevtoatalTax;

      }
          

        
          return true;
      }

      function allowance(address owner, address spender) public view override returns (uint256) {
          return _allowances[owner][spender];
      }

      function approve(address spender, uint256 amount) public override returns (bool) {
          _approve(_msgSender(), spender, amount);
          return true;
      }

      function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
          _transfer(sender, recipient, amount);
          _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
          return true;
      }

      function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
          _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
          return true;
      }

      function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
          _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
          return true;
      }

      function isExcluded(address account) public view returns (bool) {
          return _isExcluded[account];
      }

      function totalFees() public view returns (uint256) {
          return _tFeeTotal;
      }

      function reflect(uint256 tAmount) public {
          address sender = _msgSender();
          require(!_isExcluded[sender], "Excluded addresses cannot call this function");
          
        uint256 currentRate =  _getRate();
        (, uint256 t1perFee,uint256 t2perfe) = _getTValues(tAmount);
        (uint256 rAmount,,,) =_getRValues(tAmount, t1perFee,t2perfe,currentRate);
      


          _rOwned[sender] = _rOwned[sender].sub(rAmount);
          _rTotal = _rTotal.sub(rAmount);
          _tFeeTotal = _tFeeTotal.add(tAmount);
      }

      // function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
      //     require(tAmount <= _tTotal, "Amount must be less than supply");
      //     if (!deductTransferFee) {
      //         (uint256 rAmount,,,,) = _getValues(tAmount);
      //         return rAmount;
      //     } else {
      //         (,uint256 rTransferAmount,,,) = _getValues(tAmount);
      //         return rTransferAmount;
      //     }
      // }

      function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
          require(rAmount <= _rTotal, "Amount must be less than total reflections");
          uint256 currentRate =  _getRate();
          return rAmount.div(currentRate);
      }

      function excludeAccount(address account) external onlyOwner() {
          require(!_isExcluded[account], "Account is already excluded");
          if(_rOwned[account] > 0) {
              _tOwned[account] = tokenFromReflection(_rOwned[account]);
          }
          _isExcluded[account] = true;
          _excluded.push(account);
      }

      function includeAccount(address account) external onlyOwner() {
          require(_isExcluded[account], "Account is already excluded");
          for (uint256 i = 0; i < _excluded.length; i++) {
              if (_excluded[i] == account) {
                  _excluded[i] = _excluded[_excluded.length - 1];
                  _tOwned[account] = 0;
                  _isExcluded[account] = false;
                  _excluded.pop();
                  break;
              }
          }
      }

      function _approve(address owner, address spender, uint256 amount) private {
          require(owner != address(0), "ERC20: approve from the zero address");
          require(spender != address(0), "ERC20: approve to the zero address");

          _allowances[owner][spender] = amount;
          emit Approval(owner, spender, amount);
      }

      function _transfer(address sender, address recipient, uint256 amount) private {
          require(sender != address(0), "ERC20: transfer from the zero address");
          require(recipient != address(0), "ERC20: transfer to the zero address");
          require(amount > 0, "Transfer amount must be greater than zero");
          if (_isExcluded[sender] && !_isExcluded[recipient]) {
              _transferFromExcluded(sender, recipient, amount);
          } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
              _transferToExcluded(sender, recipient, amount);
          } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
              _transferStandard(sender, recipient, amount);
          } else if (_isExcluded[sender] && _isExcluded[recipient]) {
              _transferBothExcluded(sender, recipient, amount);
          } else {
              _transferStandard(sender, recipient, amount);
          }
      }


      function _reflectFee(uint256 rFee, uint256 tFee) private {
          _rTotal = _rTotal.sub(rFee);
          _tFeeTotal = _tFeeTotal.add(tFee);
      }

      // function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
      //     (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
      //     uint256 currentRate =  _getRate();
      //     (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, currentRate);
      //     return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
      // }

      function _getTValues(uint256 tAmount) private view returns (uint256, uint256,uint256) {
          uint256 tOTALFee = tAmount*totaltax/100;
          uint256 t1PerFee = tOTALFee/5;
          uint256 t2PerFee = t1PerFee*2;

          
          uint256 tTransferAmount = tAmount-tOTALFee;
          return (tTransferAmount, t1PerFee,t2PerFee);
      }

      function _getRValues(uint256 tAmount, uint256 t1perFee,uint256 t2perFee ,uint256 currentRate) private pure returns
      (uint256, uint256, uint256,uint256) {
          uint256 rAmount = tAmount.mul(currentRate);
          uint256 r1perFee = t1perFee.mul(currentRate);
          uint256 r2perfee= t2perFee.mul(currentRate);

          uint256 rTransferAmount = rAmount-r1perFee-r2perfee-r2perfee;
          return (rAmount, rTransferAmount, r1perFee,r2perfee);
      }




      function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        
        uint256 currentRate =  _getRate();
        (uint256 tTransferAmount, uint256 t1perFee,uint256 t2perfe) 
        = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 r1fee,) 
        =_getRValues(tAmount, t1perFee,t2perfe,currentRate);
        



        
          _rOwned[sender] = _rOwned[sender].sub(rAmount);
          _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 

        

      if(refle==false){
          _reflectFee(r1fee, t1perFee);
          refle=true;
      }

      if(community==false){
          swapTokensForEth(t1perFee,address(this));
          community=true;
      }
      if(marketing==false){
          swapTokensForEth(t2perfe,address(this));
          marketing=true;
      }
      if(buyBNB==false){
          swapTokensForEth(t2perfe,address(this));
          buyBNB=true;
      }


      community=false;
      marketing=false;
      buyBNB=false;
      


      emit Transfer(sender, recipient, tTransferAmount);
      }

      function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        
          uint256 currentRate =  _getRate();
        (uint256 tTransferAmount, uint256 t1perFee,uint256 t2perfe) 
        = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 r1fee,) 
        =_getRValues(tAmount, t1perFee,t2perfe,currentRate);
      
        
          _rOwned[sender] = _rOwned[sender].sub(rAmount);
          _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
          _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);    


      if(refle==false){
          _reflectFee(r1fee, t1perFee);
          refle=true;
      }

      if(community==false){
          swapTokensForEth(t1perFee,address(this));
          community=true;
      }
      if(marketing==false){
          swapTokensForEth(t2perfe,address(this));
          marketing=true;
      }
      if(buyBNB==false){
          swapTokensForEth(t2perfe,address(this));
          buyBNB=true;
      }


      community=false;
      marketing=false;
      buyBNB=false;

          emit Transfer(sender, recipient, tTransferAmount);
      }

      function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
          uint256 currentRate =  _getRate();
        (uint256 tTransferAmount, uint256 t1perFee,uint256 t2perfe) 
        = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 r1fee,) 
        =_getRValues(tAmount, t1perFee,t2perfe,currentRate);
      
          _tOwned[sender] = _tOwned[sender].sub(tAmount);
          _rOwned[sender] = _rOwned[sender].sub(rAmount);
          _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
    

        if(refle==false){
          _reflectFee(r1fee, t1perFee);
          refle=true;
        }

      if(community==false){
          swapTokensForEth(t1perFee,address(this));
          community=true;
      }
      if(marketing==false){
          swapTokensForEth(t2perfe,address(this));
          marketing=true;
      }
      if(buyBNB==false){
          swapTokensForEth(t2perfe,address(this));
          buyBNB=true;
      }


      community=false;
      marketing=false;
      buyBNB=false;


          emit Transfer(sender, recipient, tTransferAmount);
      }

      function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        
          uint256 currentRate =  _getRate();
        (uint256 tTransferAmount, uint256 t1perFee,uint256 t2perfe) 
        = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 r1fee,) 
        =_getRValues(tAmount, t1perFee,t2perfe,currentRate);
      
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
          _rOwned[sender] = _rOwned[sender].sub(rAmount);
          _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
          _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);



    
      if(refle==false){
          _reflectFee(r1fee, t1perFee);
          refle=true;
      }

      if(community==false){
          swapTokensForEth(t1perFee,address(this));
          community=true;
      }
      if(marketing==false){
          swapTokensForEth(t2perfe,address(this));
          marketing=true;
      }
      if(buyBNB==false){
          swapTokensForEth(t2perfe,address(this));
          buyBNB=true;
      }


      community=false;
      marketing=false;
      buyBNB=false;
          emit Transfer(sender, recipient, tTransferAmount);
      }












      function _getRate() private view returns(uint256) {
          (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
          return rSupply.div(tSupply);
      }

      function _getCurrentSupply() private view returns(uint256, uint256) {
          uint256 rSupply = _rTotal;
          uint256 tSupply = _tTotal;      
          for (uint256 i = 0; i < _excluded.length; i++) {
              if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
              rSupply = rSupply.sub(_rOwned[_excluded[i]]);
              tSupply = tSupply.sub(_tOwned[_excluded[i]]);
          }
          if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
          return (rSupply, tSupply);
      }






          // convert token to bnb
      function swapTokensForEth(uint256 tokenAmount, address account) private {
          // generate the uniswap pair path of token -> weth
          address[] memory path = new address[](2);
          path[0] = address(this);
          path[1] = uniswapV2Router.WETH();

          _approve(address(this), address(uniswapV2Router), tokenAmount);

          // make the swap
          uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
              tokenAmount,
              0, // accept any amount of ETH
              path,
              account,
              block.timestamp
          );
      }

        //it wiil receice tha balance to this contract
    receive() external payable {}
      


  }