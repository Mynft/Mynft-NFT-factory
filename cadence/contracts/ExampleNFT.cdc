/* 
*
*  This is an example implementation of a Flow Non-Fungible Token
*  It is not part of the official standard but it assumed to be
*  similar to how many NFTs would implement the core functionality.
*
*  This contract does not implement any sophisticated classification
*  system for its NFTs. It defines a simple NFT with minimal metadata.
*   
*/

import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"

pub contract ExampleNFT: NonFungibleToken {

  pub var totalSupply: UInt64

  pub event ContractInitialized()
  pub event Withdraw(id: UInt64, from: Address?)
  pub event Deposit(id: UInt64, to: Address?)
  pub event TokenMinted(id: UInt64, to: Address?)
  pub event TokenMintedByGrant(id: UInt64, to: Address? , minter: Address?)

  pub let CollectionStoragePath: StoragePath
  pub let CollectionPublicPath: PublicPath
  pub let MinterStoragePath: StoragePath
  pub let MinterPublicPath: PublicPath
  pub let CertificateStoragePath: StoragePath

  // metadata map for multi editions
  access(contract) var predefinedMetadata: {UInt64: {String: AnyStruct}}
  // multi edition count for metadata
  access(contract) var supplyOfTypes: {UInt64: UInt64}

  access(contract) var baseURI: String

  pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
      pub let id: UInt64

      pub let name: String
      pub let description: String
      pub let mediaType: String
      pub let thumbnail: String
      // metadata type for multi edition
      pub let typeId: UInt64
      // edition number
      pub let number: UInt64
      pub let mediaHash: String
      
      priv var metadata: {String: AnyStruct}


      access(self) let royalties: [MetadataViews.Royalty]

      init(
          id: UInt64,
          name: String,
          description: String,
          thumbnail: String,
          mediaHash: String,
          mediaType: String,
          royalties: [MetadataViews.Royalty],
          typeId: UInt64,
          number: UInt64,
          metadata: {String: AnyStruct}
      ) {
          self.id = id
          self.name = name
          self.description = description
          self.mediaType = mediaType
          self.mediaHash = mediaHash
          self.thumbnail = thumbnail
          self.royalties = royalties
          self.typeId = typeId
          self.number = number
          self.metadata = metadata
      }

      pub fun getMetadata(): {String: AnyStruct}? {
        return ExampleNFT.predefinedMetadata[self.typeId]
      }

      pub fun getNftMetadata(): {String: AnyStruct}? {
        return self.metadata
      }
  
      pub fun getViews(): [Type] {
          return [
              Type<MetadataViews.Display>(),
              Type<MetadataViews.Royalties>(),
              Type<MetadataViews.Edition>(),
              Type<MetadataViews.ExternalURL>(),
              Type<MetadataViews.NFTCollectionData>(),
              Type<MetadataViews.NFTCollectionDisplay>(),
              Type<MetadataViews.Serial>()
          ]
      }

      pub fun resolveView(_ view: Type): AnyStruct? {
        switch view {
          case Type<MetadataViews.Display>():
            var thumbnail = self.thumbnail
            if self.typeId > 0 {
              let metadata = self.getMetadata()!
              thumbnail = (metadata["thumbnail"] as? String)!

              if thumbnail != "" {
                thumbnail = thumbnail
              } 
            }
            return MetadataViews.Display(
              name: self.name,
              description: self.description,
              thumbnail: MetadataViews.HTTPFile(
                url: thumbnail
              )
            )
          case Type<MetadataViews.Editions>():
            let metadata = self.getMetadata()!
            if metadata == nil {
              return nil
            } else {
              // There is no max number of NFTs that can be minted from this contract
              // so the max edition field value is set to nil
              let number = (self.metadata["number"] as? UInt64)!
              let max = (metadata["max"] as? UInt64?)!
              let name = (metadata["name"] as? String?)!
              let editionInfo = MetadataViews.Edition(name: name, number: number, max: max)
              let editionList: [MetadataViews.Edition] = [editionInfo]
              return MetadataViews.Editions(
                editionList
              )
            }
          case Type<MetadataViews.Serial>():
            if self.typeId > 0 {
              return MetadataViews.Serial(
                self.number
              )
            }
            return MetadataViews.Serial(
              self.id
            )
          case Type<MetadataViews.Royalties>():
            var royalties = self.royalties
            if self.typeId > 0 {
            let metadata = self.getMetadata()!
            royalties = (metadata["royalties"] as? [MetadataViews.Royalty])! 
            if royalties.length > 0 {
              royalties = royalties
            }
          }
            return MetadataViews.Royalties(
              royalties
            )
          case Type<MetadataViews.ExternalURL>():
            var uri = ExampleNFT.baseURI
            var identifier = self.id.toString()
            if self.typeId > 0 {
              let metadata = self.getMetadata()!
              let baseURI = (metadata["baseURI"] as? String)!

              if baseURI != "" {
                uri = baseURI
              }
              let mediaHash = (metadata["mediaHash"] as? String)!
              if mediaHash != "" {
                identifier = mediaHash
              } else {
                identifier = self.typeId.toString()
              }
            } else {
              if self.mediaHash != "" {
                identifier = self.mediaHash
              } 
            }
            return MetadataViews.ExternalURL(uri.concat(identifier))
          case Type<MetadataViews.NFTCollectionData>():
              return MetadataViews.NFTCollectionData(
                  storagePath: ExampleNFT.CollectionStoragePath,
                  publicPath: ExampleNFT.CollectionPublicPath,
                  providerPath: /private/exampleNFTCollection,
                  publicCollection: Type<&ExampleNFT.Collection{ExampleNFT.CollectionPublic}>(),
                  publicLinkedType: Type<&ExampleNFT.Collection{ExampleNFT.CollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                  providerLinkedType: Type<&ExampleNFT.Collection{ExampleNFT.CollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                  createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                      return <-ExampleNFT.createEmptyCollection()
                  })
              )
          case Type<MetadataViews.NFTCollectionDisplay>():
              // todo midia url
              var uri = ExampleNFT.baseURI.concat(self.mediaHash)
              var mediaType = self.mediaType
              if self.typeId > 0 {
                let metadata = self.getMetadata()!
                let baseURI = (metadata["baseURI"] as? String!)
                let mediaHash = (metadata["mediaHash"] as? String!)
                if baseURI != "" {
                  uri = baseURI.concat(mediaHash)
                }

                mediaType = (metadata["mediaType"] as? String!)
                if mediaType !="" {
                  mediaType = mediaType
                }
              }
              let media = MetadataViews.Media(
                  file: MetadataViews.HTTPFile(
                      url:uri
                  ),
                  mediaType: mediaType
              )
              // todo fill out info with params
              return MetadataViews.NFTCollectionDisplay(
                  name: "The Example Collection", // params
                  description: "This collection is used as an example to help you develop your next Flow NFT.", // params
                  externalURL: MetadataViews.ExternalURL("https://example-nft.onflow.org"), // params
                  squareImage: media,
                  bannerImage: media,
                  socials: {
                      "twitter": MetadataViews.ExternalURL("https://twitter.com/flow_blockchain") // params
                  }
              )
              case Type<MetadataViews.Traits>():

                  var metadata = self.metadata

                  if self.typeId > 0 {
                    metadata = ExampleNFT.predefinedMetadata[self.typeId]!
                  }
                  // exclude mintedTime and foo to show other uses of Traits
                  let excludedTraits = ["mintedTime"]
                  let traitsView = MetadataViews.dictToTraits(dict: metadata, excludedNames: excludedTraits)

                  // mintedTime is a unix timestamp, we should mark it with a displayType so platforms know how to show it.
                  let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: self.metadata["mintedTime"]!, displayType: "Date", rarity: nil)
                  traitsView.addTrait(mintedTimeTrait)

                  // foo is a trait with its own rarity
                  // let fooTraitRarity = MetadataViews.Rarity(score: 10.0, max: 100.0, description: "Common")
                  // let fooTrait = MetadataViews.Trait(name: "foo", value: self.metadata["foo"], displayType: nil, rarity: fooTraitRarity)
                  // traitsView.addTrait(fooTrait)
                  
                  return traitsView
          }
          // default return todo detail
          return nil
      }
  }

  pub resource interface CollectionPublic {
    pub fun deposit(token: @NonFungibleToken.NFT)
    pub fun getIDs(): [UInt64]
    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
    pub fun borrowExampleNFT(id: UInt64): &ExampleNFT.NFT? {
      post {
        (result == nil) || (result?.id == id):
            "Cannot borrow ExampleNFT reference: the ID of the returned reference is incorrect"
      }
    }
  }

  pub resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
      // dictionary of NFT conforming tokens
      // NFT is a resource type with an `UInt64` ID field
      pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

      init () {
        self.ownedNFTs <- {}
      }

      // withdraw removes an NFT from the collection and moves it to the caller
      pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
        let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

        emit Withdraw(id: token.id, from: self.owner?.address)

        return <-token
      }

      // deposit takes a NFT and adds it to the collections dictionary
      // and adds the ID to the id array
      pub fun deposit(token: @NonFungibleToken.NFT) {
        let token <- token as! @ExampleNFT.NFT

        let id: UInt64 = token.id

        // add the new token to the dictionary which removes the old one
        let oldToken <- self.ownedNFTs[id] <- token

        emit Deposit(id: id, to: self.owner?.address)

        destroy oldToken
      }

      // getIDs returns an array of the IDs that are in the collection
      pub fun getIDs(): [UInt64] {
        return self.ownedNFTs.keys
      }

      // borrowNFT gets a reference to an NFT in the collection
      // so that the caller can read its metadata and call its methods
      pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
          return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
      }

      pub fun borrowExampleNFT(id: UInt64): &ExampleNFT.NFT? {
        if self.ownedNFTs[id] != nil {
            // Create an authorized reference to allow downcasting
            let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            return ref as! &ExampleNFT.NFT
        }

        return nil
      }

      pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
        let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
        let exampleNFT = nft as! &ExampleNFT.NFT
        return exampleNFT as &AnyResource{MetadataViews.Resolver}
      }

      destroy() {
          destroy self.ownedNFTs
      }
  }

  // public function that anyone can call to create a new empty collection
  pub fun createEmptyCollection(): @NonFungibleToken.Collection {
    return <- create Collection()
  }


  pub resource interface ICertificate {}

  pub resource Certificate: ICertificate {}

  /// Anyone can apply for a user certificate
  /// 
  pub fun CreateCertificate(): @Certificate {
    return <- create Certificate()
  }

  pub resource interface MinterPublic {
    pub fun mintWithAuth(
      certificate: &{ICertificate},
      recipient: &{NonFungibleToken.CollectionPublic},
      name: String,
      description: String,
      thumbnail: String,
      mediaHash: String,
      mediaType: String,
      royalties: [MetadataViews.Royalty],
      typeId: UInt64,
      metadata: {String: AnyStruct}
    )

    pub fun checkAccess(certificate: &{ICertificate}): Bool

    pub fun getAdminList(): [Address]
  }


  // Resource that an admin or something similar would own to be
  // able to mint new NFTs
  //
  pub resource NFTMinter: MinterPublic {
      priv var admins: [Address]

      // mintNFT mints a new NFT with a new ID
      // and deposit it in the recipients collection using their collection reference
      pub fun mintNFT(
          recipient: &{NonFungibleToken.CollectionPublic},
          name: String,
          description: String,
          thumbnail: String,
          mediaHash: String,
          mediaType: String,
          royalties: [MetadataViews.Royalty],
          typeId: UInt64,
          metadata: {String: AnyStruct}
      ) {
          let currentBlock = getCurrentBlock()
          metadata["mintedBlock"] = currentBlock.height
          metadata["mintedTime"] = currentBlock.timestamp
          metadata["minter"] = recipient.owner!.address
          var NFTNum: UInt64 = 0

          if typeId != nil && typeId > 0 {
            let preMetadata = ExampleNFT.predefinedMetadata[typeId]!
            let typeSupply = ExampleNFT.supplyOfTypes[typeId] ?? 0

            let max = (preMetadata["max"] as? UInt64?)!

            if typeSupply == max! {
              panic("Edition number reach max with typeId: ".concat(typeId.toString()))
            }
            if typeSupply == 0 {
              ExampleNFT.supplyOfTypes[typeId] = 1
              NFTNum = 1
            } else {
              ExampleNFT.supplyOfTypes[typeId] = typeSupply! + (1 as UInt64)
              NFTNum = typeSupply!
            }
            metadata["number"] = NFTNum
          }
            // create a new NFT
          var newNFT <- create NFT(
            id: ExampleNFT.totalSupply,
            name: name,
            description: description,
            thumbnail: thumbnail,
            mediaHash: mediaHash,
            mediaType: mediaType,
            royalties: royalties,
            typeId: typeId,
            number: NFTNum,
            metadata: metadata
          )

          // deposit it in the recipient's account using their reference
          recipient.deposit(token: <-newNFT)
          emit TokenMinted(id: ExampleNFT.totalSupply, to: recipient.owner?.address )

          ExampleNFT.totalSupply = ExampleNFT.totalSupply + UInt64(1)
      }

      // UpdateMetadata
      // Update metadata for a typeId
      //
      pub fun updateMetadata(typeId: UInt64, metadata: {String: AnyStruct}) {
        let currentSupply = ExampleNFT.supplyOfTypes[typeId]
        if currentSupply != nil && currentSupply! > 0 {
          let max = (metadata["max"] as? UInt64)!
          assert(currentSupply! <= max, message: "Can not set max lower than supply")
        }
        ExampleNFT.predefinedMetadata[typeId] = metadata
      }

      // BatchMintNFT for multi edition
      // Mints a batch of new NFTs
      // and deposit it in the recipients collection using their collection reference
      //
      pub fun batchMintNFT(recipient: &{NonFungibleToken.CollectionPublic}, typeId: UInt64, count: Int) {
        pre {
          ExampleNFT.predefinedMetadata[typeId] != nil : "Can not find metadata, please define before mint"
        }
          let metadata = ExampleNFT.predefinedMetadata[typeId]!
          var index = 0

          while index < count {
            self.mintNFT(
              recipient: recipient,
              name: "",
              description: "",
              thumbnail:  "",
              mediaHash:  "",
              mediaType:  "",
              royalties:  [],
              typeId: typeId,
              metadata: {}
            )
            index = index + 1
          }
      }

    // updateMetadata
    // Update metadata for a typeId
    //
    pub fun updateBaseURI(uri: String) {
      ExampleNFT.baseURI = uri
    }

    pub fun addAdmin(address: Address) {
      pre {
        !self.admins.contains(address) : "Admin already exist"
      }
      self.admins.append(address)
    }

    pub fun removeAdmin(address: Address) {
      pre {
        self.admins.contains(address) : "Admin not exist"
      }
      let idx = self.admins.firstIndex(of: address)
      self.admins.remove(at: idx!)
    }

    pub fun mintWithAuth(
      certificate: &{ICertificate},
      recipient: &{NonFungibleToken.CollectionPublic},
      name: String,
      description: String,
      thumbnail: String,
      mediaHash: String,
      mediaType: String,
      royalties: [MetadataViews.Royalty],
      typeId: UInt64,
      metadata: {String: AnyStruct}
    ) {
      self.mintNFT(recipient: recipient, name: name, description: description, thumbnail: thumbnail, mediaHash: mediaHash, mediaType: mediaType, royalties: royalties, typeId: typeId, metadata: metadata)
      emit TokenMintedByGrant(id: ExampleNFT.totalSupply -1, to: recipient.owner?.address, minter: certificate.owner?.address)
    }

    pub fun checkAccess(certificate: &{ICertificate}): Bool {
      let address = certificate.owner!.address
      return self.admins.contains(address)
    }

    pub fun getAdminList(): [Address] {
      return self.admins
    }

    init(){
      self.admins = []
    }
  }

  pub fun fetch(_ from: Address, itemID: UInt64): &ExampleNFT.NFT? {
    let collection = getAccount(from)
        .getCapability(ExampleNFT.CollectionPublicPath)!
        .borrow<&ExampleNFT.Collection>()
        ?? panic("Couldn't get collection")
    // We trust SeeDAONFT.Collection.borowSeeDAONFT to get the correct itemID
    // (it checks it before returning it).
    return collection.borrowExampleNFT(id: itemID)
  }

  // getMetadata
  // Get the metadata for a specific type of SeeDAONFT
  //
  pub fun getMetadata(typeId: UInt64): {String: AnyStruct}? {
      return ExampleNFT.predefinedMetadata[typeId]
  }

  // getTypeSupply
  // Get NFT supply of typeId
  //
  pub fun getTypeSupply(typeId: UInt64): UInt64? {
      return ExampleNFT.supplyOfTypes[typeId]
  }

  init() {
    // Initialize the total supply
    self.totalSupply = 0
    self.predefinedMetadata = {}
    self.supplyOfTypes = {}
    self.baseURI = ""
    // Set the named paths
    self.CollectionStoragePath = /storage/exampleNFTCollection
    self.CollectionPublicPath = /public/exampleNFTCollection
    self.MinterStoragePath = /storage/exampleNFTMinter
    self.MinterPublicPath = /public/exampleNFTMinter
    self.CertificateStoragePath = /storage/exampleNFTCertificate

    
    // Create a Collection resource and save it to storage
    let collection <- create Collection()
    self.account.save(<-collection, to: self.CollectionStoragePath)

    // create a public capability for the collection
    self.account.link<&ExampleNFT.Collection{NonFungibleToken.CollectionPublic, ExampleNFT.CollectionPublic, MetadataViews.ResolverCollection}>(
      self.CollectionPublicPath,
      target: self.CollectionStoragePath
    )

    // Create a Minter resource and save it to storage
    let minter <- create NFTMinter()
    self.account.save(<-minter, to: self.MinterStoragePath)
    self.account.link<&ExampleNFT.NFTMinter{MinterPublic}>(
      self.MinterPublicPath,
      target: self.MinterStoragePath
    )

    emit ContractInitialized()
  }
}