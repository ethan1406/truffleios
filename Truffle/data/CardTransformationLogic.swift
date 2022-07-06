//
//  CardTransformationLogic.swift
//  Truffle
//
//  Created by Ethan Chang on 7/1/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import Bugsnag
import Kingfisher
import Network

class CardTransformationLogic {

    private let transformationService: CardTransformationService

    var cardImageToTransformation = [Int : CardTransformation]()

    init(transformationService: CardTransformationService) {
        self.transformationService = transformationService
    }


    func getCardImages() async throws -> Result<[CardCGImage], TransformationServiceError> {

        let result = try await transformationService.getCardTransformationData()
        switch result {
        case .success(let response):
            let dict = response.toCardImageToTransformationMap()
            cardImageToTransformation = dict

            let cgImages = await fetchAllCardImages(cardImageToTransformation.values.map { $0.cardImage })

            return .success(cgImages )
        case .failure(.genericError):
            return .failure(.genericError)
        }
        
    }

    func getCardTransformation(imageId: Int) -> CardTransformation? {
        return cardImageToTransformation[imageId]
    }


    func convertToCgImage(_ cardImage: CardImage) async -> CardCGImage? {

        guard let url = URL.init(string: cardImage.imageUrl) else { return nil }

        let resource = ImageResource(downloadURL: url, cacheKey: String(cardImage.imageId))

        let result = await retrieveImage(resource: resource)

        switch result {
        case .success(let uiImage):
            guard let cgImage = uiImage.image.cgImage else { return nil }

            return CardCGImage(
                imageId: cardImage.imageId,
                cgImage: cgImage,
                imageName: cardImage.imageName,
                physicalSize: cardImage.physicalSize
            )
        case .failure(let error):
            Bugsnag.notifyError(error)
            return nil
        }

    }

    private func fetchAllCardImages(_ cardImages: [CardImage]) async -> [CardCGImage] {
        await withTaskGroup(of: CardCGImage?.self) { group in
            for cardImage in cardImages {
                group.addTask { await self.convertToCgImage(cardImage) }
            }

            var images = [CardCGImage]()
            for await result in group {
                if let image = result {
                    images.append(image)
                }
            }
            return images
        }

    }

    private func retrieveImage(resource: ImageResource) async -> Result<RetrieveImageResult, KingfisherError> {
        await withCheckedContinuation { continuation in
            KingfisherManager.shared.retrieveImage(with: resource) { result in
                continuation.resume(returning: result)
            }
        }
    }

}


extension GetCardTransformationDataResponse {

    func toCardImageToTransformationMap() -> [Int : CardTransformation] {
        let tupleArray = augmentedTransformations.map { transformation -> [Int : CardTransformation] in
            transformation.augmentedImages.reduce(into: [Int: CardTransformation]()) { dict, image in
                dict[Int(image.imageID)] = CardTransformation(
                    transformationId: Int(transformation.transformationID),
                    attachments: transformation.attachmentView.linkButtons.map {
                        Attachment(
                            title: $0.text,
                            imageUrl: $0.imageURL,
                            colorCode: $0.colorCode,
                            webUrl: $0.webURL
                        )
                    },
                    attachmentViewConfig: AttachmentViewConfig(
                        uiSize: TruffleSize(
                            width: transformation.attachmentView.attachmentUiViewSize.width,
                            height: transformation.attachmentView.attachmentUiViewSize.height
                        ),
                        widthScaleToImageWidth: transformation.attachmentView.attachmentWidthScaleToImageWidth,
                        position: TrufflePosition(
                            xScaleToImageWidth: transformation.attachmentView.position.xScaleToImageWidth,
                            y: transformation.attachmentView.position.y,
                            zScaleToImageHeight: transformation.attachmentView.position.zScaleToImageHeight
                        )
                    ),
                    animationEffectConfig: AnimationEffectConfig(
                        lottieUrl: transformation.animationEffect.lottieURL,
                        size: TruffleSize(
                            width: transformation.animationEffect.effectViewSize.width,
                            height: transformation.animationEffect.effectViewSize.height
                        ),
                        position: TrufflePosition(
                            xScaleToImageWidth: transformation.animationEffect.position.xScaleToImageWidth,
                            y: transformation.animationEffect.position.y,
                            zScaleToImageHeight: transformation.animationEffect.position.zScaleToImageHeight
                        )
                    ),
                    cardImage: CardImage(
                        imageId: Int(image.imageID),
                        imageUrl: image.imageURL,
                        imageName: image.imageName,
                        physicalSize: TruffleSize(
                            width: image.physicalImageSize.width,
                            height: image.physicalImageSize.height
                        )
                    ),
                    cardVideo: CardVideo(
                        videoUrl: transformation.augmentedVideo.videoURL,
                        widthScaleToImageWidth: transformation.augmentedVideo.videoWidthScaleToImageWidth,
                        videoWidthPx: Int(transformation.augmentedVideo.videoDimensionWidthPx),
                        videoHeightPx: Int(transformation.augmentedVideo.videoDimensionHeightPx),
                        position: TrufflePosition(
                            xScaleToImageWidth: transformation.augmentedVideo.position.xScaleToImageWidth,
                            y: transformation.augmentedVideo.position.y,
                            zScaleToImageHeight: transformation.augmentedVideo.position.zScaleToImageHeight
                        )
                    )
                )

            }
        }
        .flatMap { $0 }

        return Dictionary(tupleArray, uniquingKeysWith: { (_, last) in last })
    }
}
