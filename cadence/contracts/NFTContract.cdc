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
  pub event TokenMintedByGrant(id: UInt64, to: Address? , minter?: Address)

  pub let CollectionStoragePath: StoragePath
  pub let CollectionPublicPath: PublicPath
  pub let MinterStoragePath: StoragePath
  pub let MinterPublicPath: PublicPath
  pub let CertificateStoragePath: StoragePath

  // metadata map for multi editions
  access(contract) var predefinedMetadata: {UInt64: Metadata}
  // multi edition count for metadata
  access(contract) var supplyOfTypes: {UInt64: UInt64}

  access(contract) var baseURI: String

  // Metadata for multi edition
  pub struct Metadata {
      pub let name: String
      pub let description: String

      // mediaType: MIME type of the media
      // - image/png
      // - image/jpeg
      // - image/svg+xml
      // - video/mp4
      // - audio/mpeg
      pub let mediaType: String

      // mediaHash: dstorage storage hash
      pub let mediaHash: String
      pub let thumbnail: String

      pub let baseURI: String

      pub let max: UInt64

      pub let royalties: [MetadataViews.Royalty]

      pub let props: {String: String}


      init(name: String, description: String, mediaType: String, mediaHash: String, baseURI: String, thumbnail: String, max: UInt64, royalties: [MetadataViews.Royalty], props: {String: String}) {
          self.name = name
          self.description = description
          self.mediaType = mediaType
          self.mediaHash = mediaHash
          self.baseURI = baseURI
          self.thumbnail = thumbnail
          self.max = max
          self.royalties = royalties
          self.props = props
      }
  }


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
      
      priv var props: {String: String}


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
          props: {String: String}
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
          self.props = props
      }

      pub fun getMetadata(): Metadata? {
        return ExampleNFT.predefinedMetadata[self.typeId]
      }

      pub fun getProps(): {String: String}? {
        return self.props
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
              return MetadataViews.Display(
                name: self.name,
                description: self.description,
                thumbnail: MetadataViews.HTTPFile(
                  url: self.thumbnail
                )
              )
          case Type<MetadataViews.Editions>():
            let metadata = self.getMetadata()!
            // There is no max number of NFTs that can be minted from this contract
            // so the max edition field value is set to nil
            let editionInfo = MetadataViews.Edition(name: metadata.name, number: self.number, max: metadata.max)
            let editionList: [MetadataViews.Edition] = [editionInfo]
            return MetadataViews.Editions(
              editionList
            )
          case Type<MetadataViews.Serial>():
            return MetadataViews.Serial(
              self.id
            )
          case Type<MetadataViews.Royalties>():
            var royalties = self.royalties
            if self.typeId > 0 {
            let metadata = self.getMetadata()!
            if metadata.baseURI != "" {
              royalties = metadata.royalties
            }
          }
            return MetadataViews.Royalties(
              royalties
            )
          case Type<MetadataViews.ExternalURL>():
            var uri = ExampleNFT.baseURI
            if self.typeId > 0 {
              let metadata = self.getMetadata()!
              if metadata.baseURI != "" {
                uri = metadata.baseURI
              }
            }
            return MetadataViews.ExternalURL(uri.concat(self.mediaHash))
          case Type<MetadataViews.NFTCollectionData>():
              return MetadataViews.NFTCollectionData(
                  storagePath: ExampleNFT.CollectionStoragePath,
                  publicPath: ExampleNFT.CollectionPublicPath,
                  providerPath: /private/exampleNFTCollection,
                  publicCollection: Type<&ExampleNFT.Collection{ExampleNFT.ExampleNFTCollectionPublic}>(),
                  publicLinkedType: Type<&ExampleNFT.Collection{ExampleNFT.ExampleNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                  providerLinkedType: Type<&ExampleNFT.Collection{ExampleNFT.ExampleNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
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
                if metadata.baseURI != "" {
                  uri = metadata.baseURI.concat(metadata.mediaHash)
                }
                mediaType = metadata.mediaType
              }
              let media = MetadataViews.Media(
                  file: MetadataViews.HTTPFile(
                      url:uri
                  ),
                  mediaType: mediaType
              )
              // todo fill out info with params
              return MetadataViews.NFTCollectionDisplay(
                  name: "The Example Collection",
                  description: "This collection is used as an example to help you develop your next Flow NFT.",
                  externalURL: MetadataViews.ExternalURL("https://example-nft.onflow.org"),
                  squareImage: media,
                  bannerImage: media,
                  socials: {
                      "twitter": MetadataViews.ExternalURL("https://twitter.com/flow_blockchain")
                  }
              )
          }
          // default return todo detail
          return nil
      }
  }

  pub resource interface ExampleNFTCollectionPublic {
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

  pub resource Collection: ExampleNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
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
      props: {String: String}
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
          props: {String: String}
      ) {
          var NFTNum: UInt64 = 0

          if typeId != nil && typeId > 0 {
            let metadata = ExampleNFT.predefinedMetadata[typeId]!
            let typeSupply = ExampleNFT.supplyOfTypes[typeId]
            if typeSupply == metadata.max {
              panic("Edition number reach max with typeId: ".concat(typeId.toString()))
            }
            if typeSupply == nil {
              ExampleNFT.supplyOfTypes[typeId] = 1
              NFTNum = 1
            } else {
              ExampleNFT.supplyOfTypes[typeId] = typeSupply! + (1 as UInt64)
              NFTNum = typeSupply!
            }
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
            props: props
          )

          // deposit it in the recipient's account using their reference
          recipient.deposit(token: <-newNFT)
          emit TokenMinted(id: ExampleNFT.totalSupply, to: recipient.owner?.address )

          ExampleNFT.totalSupply = ExampleNFT.totalSupply + UInt64(1)
      }

      // UpdateMetadata
      // Update metadata for a typeId
      //
      pub fun updateMetadata(typeId: UInt64, metadata: Metadata) {
        let currentSupply = ExampleNFT.supplyOfTypes[typeId]
        if currentSupply != nil && currentSupply! > 0 {
          assert(currentSupply! <= metadata.max, message: "Can not set max lower than supply")
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
              name: metadata.name,
              description: metadata.description,
              thumbnail: metadata.thumbnail,
              mediaHash: metadata.mediaHash,
              mediaType: metadata.mediaType,
              royalties: metadata.royalties,
              typeId: typeId
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
      props: {String: String}
    ) {
      self.mintNFT(recipient: recipient, name: name, description: description, thumbnail: thumbnail, mediaHash: mediaHash, mediaType: mediaType, royalties: royalties, typeId: typeId, props: props)
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
  pub fun getMetadata(typeId: UInt64): Metadata? {
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
    self.account.link<&ExampleNFT.Collection{NonFungibleToken.CollectionPublic, ExampleNFT.ExampleNFTCollectionPublic, MetadataViews.ResolverCollection}>(
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