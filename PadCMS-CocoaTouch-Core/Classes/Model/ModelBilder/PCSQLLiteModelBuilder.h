//
//  PCSQLLiteModelBuilder.h
//  Pad CMS
//
//  Created by Rustam Mallakurbanov on 15.02.12.
//  Copyright (c) PadCMS (http://www.padcms.net)
//
//
//  This software is governed by the CeCILL-C  license under French law and
//  abiding by the rules of distribution of free software.  You can  use,
//  modify and/ or redistribute the software under the terms of the CeCILL-C
//  license as circulated by CEA, CNRS and INRIA at the following URL
//  "http://www.cecill.info".
//  
//  As a counterpart to the access to the source code and  rights to copy,
//  modify and redistribute granted by the license, users are provided only
//  with a limited warranty  and the software's author,  the holder of the
//  economic rights,  and the successive licensors  have only  limited
//  liability.
//  
//  In this respect, the user's attention is drawn to the risks associated
//  with loading,  using,  modifying and/or developing or reproducing the
//  software by the user in light of its specific status of free software,
//  that may mean  that it is complicated to manipulate,  and  that  also
//  therefore means  that it is reserved for developers  and  experienced
//  professionals having in-depth computer knowledge. Users are therefore
//  encouraged to load and test the software's suitability as regards their
//  requirements in conditions enabling the security of their systems and/or
//  data to be ensured and,  more generally, to use and operate it in the
//  same conditions as regards security.
//  
//  The fact that you are presently reading this means that you have had
//  knowledge of the CeCILL-C license and that you accept its terms.
//

/**
 @class PCSQLLiteModelBuilder
 @brief Responsible for Data Model creating. Model creating goes in two stages. First stage is PCApplication initialization and filling basic magazine information received from client.getIssues. On the second stage downloaded magazines fills with data from sqlite database and magazines structure is built.
 */



#import <UIKit/UIKit.h>
#import "PCData.h"

@interface PCSQLLiteModelBuilder : NSObject

+ (void)addPagesFromSQLiteBaseWithPath:(NSString*)path toRevision:(PCRevision*)revision;

/**
 @brief Creates data model
 
 @param applicatinDictionary - Dictionary with information received from client.getIssues
 */
//+(PCApplication*)buildApplicationFromDictionary:(NSDictionary*)applicatinDictionary;

/**
 @brief Updates data model
 
 @param application - PCApplication object which needs updating
 @param applicatinDictionary - Dictionary with information received from client.getIssues
 */
//+(void)updateApplication:(PCApplication*)application withDictionary:(NSDictionary*)applicatinDictionary;

@end
