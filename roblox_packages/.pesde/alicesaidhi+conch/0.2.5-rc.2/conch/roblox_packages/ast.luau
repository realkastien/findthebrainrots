local module = require(script.Parent.Parent.Parent.Parent.Parent["alicesaidhi+conch_ast"]["0.2.1"]["conch_ast"]["src"]["lib"])
export type TokenKindText  = module.TokenKindText 
export type TokenKindRest  = module.TokenKindRest 
export type Token<T = TokenKindRest | TokenKindText> = module.Token<T >
export type Result  = module.Result 
return module