//
//  CardTransformationService.swift
//  Truffle
//
//  Created by Ethan Chang on 6/29/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import GRPC

struct CardTransformationService {

    func getCardTransformationData() async throws -> Result<GetCardTransformationDataResponse, TransformationServiceError> {
    
        let group = PlatformSupport.makeEventLoopGroup(loopCount: 1)
        defer {
            try? group.syncShutdownGracefully()
        }
        let channel = ClientConnection
            .usingPlatformAppropriateTLS(for: group)
            .connect(host: Constants.apiBaseUrl, port: Constants.apiEndpointPort)
//
//        let channel = try GRPCChannelPool.with(
//            target: .host("api.trufflear.com", port: self.port),
//            transportSecurity: .tls( .makeClientConfigurationBackedByNIOSSL()),
//            eventLoopGroup: group
//        )
        defer {
            try? channel.close().wait()
        }

        let cardTransformationServiceClient = CardTransformationAsyncClient(channel: channel)

        let request: GetCardTransformationDataRequest = .with {
            $0.platform = Constants.apiRequestPlatform
        }

        do {
            let response = try await cardTransformationServiceClient.getCardTransformationData(request)
            print("responseEthan")
            print(response.augmentedTransformations)

            return .success(response)
        }  catch {
            print("failed")

            return .failure(TransformationServiceError.genericError)
        }

    }
}

enum TransformationServiceError: Error {
    case genericError
}
